package main

import "core:fmt"
import "core:math/linalg"
import "core:mem"

import rl "vendor:raylib"

import "hex"
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
        position = {0, 5, -1}, up = {0, 1, 0},
        target = 2,
    }

    hex_map: hex.Map
    hex.map_gen_hexagon(&hex_map, 3)
    defer delete(hex_map)

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
        rl.ClearBackground(rl.BLACK)

        rl.BeginMode3D(camera)
            draw_board(hex_map)
        rl.EndMode3D()

        draw_gui(&camera)
    }
}

hex_tile_size := rl.Vector2{linalg.SQRT_THREE, 1.5}

draw_board :: proc(hex_map: hex.Map) {
    rl.DrawLine3D({0, 1, 0}, {5, 1, 0}, rl.RED)

    for h in hex_map {
        point := hex.hex_to_world(hex.layout, h)
        pos := rl.Vector3{point.x, 0, point.y}

        rl.DrawCylinder     (pos, 1, 1, 1, 6, rl.BLUE)
        rl.DrawCylinderWires(pos, 1, 1, 1, 6, rl.WHITE)
    }

    if true do return

    for q in 0..<10 {
        for r in 0..<10 {
            point := hex.hex_to_world(hex.layout, hex.hex(q, r))
            pos := rl.Vector3{point.x, 0, point.y}

            rl.DrawCylinder     (pos, 1, 1, 1, 6, rl.BLUE)
            rl.DrawCylinderWires(pos, 1, 1, 1, 6, rl.WHITE)
        }
    }
}

CAM_MOVE := f32(10)
CAM_ROT  := f32(5)

camera_movement :: proc(camera: ^rl.Camera, dt: f32) {
    forward := int(rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)) - int(rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN))
    strafe  := int(rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT)) - int(rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT))
    movement := dt * CAM_MOVE * rl.Vector3{ f32(forward), f32(strafe), 0 }

    rot: rl.Vector2
    if rl.IsCursorHidden() {
        rot = dt * CAM_ROT * rl.GetMouseDelta()
    }
    rl.UpdateCameraPro(camera, movement, {rot.x, rot.y, 0}, rl.GetMouseWheelMove() * 2)
}