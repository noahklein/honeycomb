package main

import "core:fmt"
import "core:mem"

import rl "vendor:raylib"

import "ngui"
import "rlutil"

camera: rl.Camera
timescale: f32 = 1

main :: proc() {
    when ODIN_DEBUG {
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
                for _, entry in track.allocation_map {
                    fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
                }
            }
            if len(track.bad_free_array) > 0 {
                fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
                for entry in track.bad_free_array {
                    fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
                }
            }
            mem.tracking_allocator_destroy(&track)
        }
    }
    defer free_all(context.temp_allocator)

    rl.SetTraceLogLevel(.ALL if ODIN_DEBUG else .WARNING)
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(1600, 900, "Farm")
    defer rl.CloseWindow()

    rl.rlEnableSmoothLines()

    // Before we do anything, clear the screen to avoid transparent windows.
    rl.BeginDrawing()
        rl.ClearBackground(rl.GRAY)
    rl.EndDrawing()

    // camera = rl.Camera2D{ zoom = 1, offset = rlutil.screen_size() / 2 }
    camera = rl.Camera{
        projection = .PERSPECTIVE, fovy = 90,
        position = {0, 0, -10}, up = {0, 1, 0},
        target = {0, 0, 0},
    }

    hex_tile_model := rl.LoadModel("assets/hex-tile.glb")
    defer rl.UnloadModel(hex_tile_model)

    ngui.init()
    defer ngui.deinit()

    rlutil.profile_init(2)
    defer rlutil.profile_deinit()

     for !rl.WindowShouldClose() {
        defer free_all(context.temp_allocator)

        dt := rl.GetFrameTime() * timescale

        if rl.IsMouseButtonPressed(.RIGHT) {
            if rl.IsCursorHidden() do rl.EnableCursor()
            else do rl.DisableCursor()
        }

        if rlutil.profile_begin("update") {
            camera_movement(&camera, dt)
        }

        rlutil.profile_begin("draw")
        rl.BeginDrawing()
        defer rl.EndDrawing()
        rl.ClearBackground(rl.BROWN)

        rl.BeginMode3D(camera)
            draw_board(hex_tile_model)
        rl.EndMode3D()

        draw_gui(&camera)
    }
}

hex_tile_angle : f32 = 60

draw_board :: proc(tile_model: rl.Model) {
    for x in 0..<10 {
        for y in 0..<10 {
            pos := rl.Vector3{f32(x), -5, f32(y)}
            if y % 2 == 1 {
                pos.x += 0.5
            }
            rl.DrawModelEx(tile_model, pos, {0, 1, 0}, hex_tile_angle, 1, rl.BLUE)
            rl.DrawModelWiresEx(tile_model, pos, {0, 1, 0}, hex_tile_angle, 1, rl.WHITE)
        }
    }
}

CAM_MOVE := f32(10)
CAM_ROT  := f32(5)

camera_movement :: proc(camera: ^rl.Camera, dt: f32) {
    forward := int(rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)) - int(rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN))
    strafe  := int(rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT)) - int(rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT))
    movement := dt * CAM_MOVE * rl.Vector3{ f32(forward), f32(strafe), 0 }

    rot := dt * CAM_ROT * rl.GetMouseDelta()
    rl.UpdateCameraPro(camera, movement, {rot.x, rot.y, 0}, rl.GetMouseWheelMove() * 2)
}