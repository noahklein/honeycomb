package rlutil

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "core:os"
import "core:time"

ShaderWatch :: struct {
	path: string,
	last_load: i64,
	shader: rl.Shader,
}

ShaderError :: enum {
	None,
	ReadFile,
	CompileFailed,
	LinkFailed,
	NeedTwoShaders,
	InvalidVert,
	InvalidFrag,
	WatchFailed,
}

shader_load :: proc(filename: string) -> (ShaderWatch, ShaderError) {
    context.allocator = context.temp_allocator
    file, ok := os.read_entire_file_from_filename(filename)
    if !ok {
        return {}, .ReadFile
    }
    shader_src, err := preprocess(string(file))
    
    if err != nil {
        return {}, err
    }

	return {
		path = filename,
		shader = rl.LoadShaderFromMemory(shader_src.vert, shader_src.frag),
		last_load = time.now()._nsec,
	}, nil
}


@(deferred_none=shader_end)
shader_begin :: proc(sw: ShaderWatch) -> bool {
	rl.BeginShaderMode(sw.shader)
	return true
}

shader_end :: proc() { rl.EndShaderMode() }

@(private="file")
Preprocess :: struct {
	vert: cstring,
	frag: cstring,
}

// Vertex and fragment shaders are combined into a single file.
// Each must begin with one of (including new-line):
// #type vertex
// #type fragment
@(private="file")
preprocess :: proc(s: string) -> (Preprocess, ShaderError) {
	splits := strings.split(s, "#type ")
	if len(splits) != 3 {
		return Preprocess{}, .NeedTwoShaders
	}

	vert, frag := splits[1], splits[2]
	if !strings.has_prefix(vert, "vertex") {
		return Preprocess{}, .InvalidVert
	}
	if !strings.has_prefix(frag, "fragment") {
		return Preprocess{}, .InvalidFrag
	}

    vert = vert[len("vertex\n"):]
    frag = frag[len("fragment\n"):]

	return Preprocess{
		vert = strings.clone_to_cstring(vert),
		frag = strings.clone_to_cstring(frag),
	}, nil
}


shader_watch :: proc(watch: ^ShaderWatch) -> ShaderError {
	now := time.now()._nsec
	defer watch.last_load = now

	stat, errno := os.stat(watch.path, context.temp_allocator)
	if errno != os.ERROR_NONE {
		fmt.eprintln("os.stat error:", errno)
		return .WatchFailed
	}

	if stat.modification_time._nsec < watch.last_load {
		return nil
	}

	new_shader, err := shader_load(watch.path)
	if err != nil {
		fmt.eprintln("Failed to reload shader:", err)
		return err
	}

	fmt.println("✅ Shader reload", watch.path)

	rl.UnloadShader(watch.shader)
	watch.shader = new_shader.shader
	return nil
}