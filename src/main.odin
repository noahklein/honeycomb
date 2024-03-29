package main

import "core:fmt"
import "core:mem"
import "core:slice"

import rl "vendor:raylib"

import "fight"
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
    rl.SetConfigFlags({.VSYNC_HINT, .MSAA_4X_HINT })
    rl.InitWindow(1600, 900, "Honeycomb")
    defer rl.CloseWindow()

    rl.rlSetLineWidth(4)
    rl.rlEnableSmoothLines()

    // Before we do anything, clear the screen to avoid transparent windows.
    rl.BeginDrawing()
        rl.ClearBackground(rl.GRAY)
    rl.EndDrawing()

    camera = rl.Camera{
        projection = .PERSPECTIVE, fovy = 90,
        position = {0, 5, -1}, up = {0, 1, 0},
        target = 2,
    }

    fight.init()
    defer fight.deinit()
    append(&fight.fighters,
        fight.Fighter{ team = .Blue, hex = hex.hex( 0,  0), moves_remaining = fight.MOVES },
        fight.Fighter{ team = .Blue, hex = hex.hex(-3, -1), moves_remaining = fight.MOVES },
        fight.Fighter{ team = .Red,  hex = hex.hex(-2,  3), moves_remaining = fight.MOVES },
        fight.Fighter{ team = .Red,  hex = hex.hex( 4,  3), moves_remaining = fight.MOVES },
    )

    ngui.init()
    defer ngui.deinit()

    rlutil.profile_init(2)
    defer rlutil.profile_deinit()

     for !rl.WindowShouldClose() {
        defer free_all(context.temp_allocator)

        dt := rl.GetFrameTime() * timescale

        if rl.IsMouseButtonPressed(.MIDDLE) {
            if rl.IsCursorHidden() do rl.EnableCursor()
            else do rl.DisableCursor()
        }

        hovered_tile: hex.Hex
        if rlutil.profile_begin("update") {
            camera_movement(&camera, dt)

            fight.deck_update(fight.deck)
            is_hovering_gui := fight.hand_hovered_card(fight.deck) != -1 || ngui.want_mouse()

            ray := rl.GetMouseRay(rl.GetMousePosition(), camera)
            if hovered, ok := get_hovered_tile(fight.board, ray); ok && !is_hovering_gui {
                if hovered_tile != hovered {
                    hovered_tile = hovered
                    fight.path_update(hovered)
                }

                if rl.IsMouseButtonPressed(.LEFT) {
                    if id, occupied := fight.get_fighter_by_tile(hovered); occupied {
                        if fight.fighters[id].team == fight.side_to_move {
                            fight.set_active_fighter(id)
                        }
                    } else if hovered in fight.paths.legal {
                        fight.fighters[fight.active_fighter].hex = hovered
                        fight.fighters[fight.active_fighter].moves_remaining -= len(fight.paths.path)
                        fight.set_active_fighter(fight.active_fighter) // Re-calculate moves.
                    }
                }
            }

            if rl.IsMouseButtonPressed(.RIGHT) do fight.deselect_fighter()
            if rl.IsKeyPressed(.SPACE)         do fight.end_turn()
            if rl.IsKeyPressed(.R)             do fight.deck_draw(&fight.deck)
        }

        if rlutil.profile_begin("draw") {
            rl.BeginDrawing()
            defer rl.EndDrawing()
            rl.ClearBackground(rl.BLACK)

            rl.BeginMode3D(camera)
                draw_board(fight.board, hovered_tile)
            rl.EndMode3D()

            fight.draw_cards_ui(fight.deck)
            draw_gui(&camera)
        }
    }
}

draw_board :: proc(hex_board: hex.Board, hovered: hex.Hex) {
    hovered_capital := hex_board[hovered].capital

    for h, tile in hex_board {
        point := hex.hex_to_world(h)
        pos := rl.Vector3{point.x, 0, point.y}

        color := hex.TILE_COLORS[tile.type]
        if h in fight.paths.legal {
            color = rl.BEIGE
        }
        if slice.contains(fight.paths.path[:], h) {
            color = rl.GREEN
        } else if hovered == h  {
            color = rl.DARKGREEN
        }
        color = hex.board_kingdom_color(fight.board, fight.kingdoms_by_capital, h)
        if tile.capital == hovered_capital {
            color = ngui.lerp_color(color, rl.WHITE, 0.25)
        }

        // @TODO: Slow; load model and do instanced rendering.
        RADIUS :: 1
        HEIGHT :: 1
        rl.DrawCylinder     (pos, RADIUS, RADIUS, HEIGHT, 6, color)
        // rl.DrawCylinderWires(pos, RADIUS, RADIUS, HEIGHT, 6, rl.WHITE)

        if h in fight.kingdoms_by_capital {
            rl.DrawCubeV(pos + {0, 1, 0}, 0.25, rl.GOLD)
        }
    }

    // for fighter in fight.fighters {
    //     point := hex.hex_to_world(fighter.hex)
    //     pos := rl.Vector3{point.x, 1.5, point.y}

    //     color := rl.RED if fighter.team == .Red else rl.DARKBLUE
    //     rl.DrawCapsule(pos, pos + {0, 1, 0}, 0.5, 16, 4, color)
    // }
}


camera_movement :: proc(camera: ^rl.Camera, dt: f32) {
    MOVE ::  10
    ROT  ::   5
    ZOOM :: 200

    forward := int(rl.IsKeyDown(.W) || rl.IsKeyDown(.UP))    - int(rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN))
    strafe  := int(rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT)) - int(rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT))
    movement := dt * MOVE * rl.Vector3{ f32(forward), f32(strafe), 0 }

    rot: rl.Vector2
    if rl.IsCursorHidden() {
        rot = dt * ROT * rl.GetMouseDelta()
    }

    zoom := dt * ZOOM * -rl.GetMouseWheelMove()
    rl.UpdateCameraPro(camera, movement, {rot.x, rot.y, 0}, zoom)
}

@(require_results)
get_hovered_tile :: proc(hex_board: hex.Board, ray: rl.Ray) -> (hex.Hex, bool) {
    // Get point of impact with mouse ray and a plane.
    t := (1 - ray.position.y) / ray.direction.y // Solve for t with y = 1.
    plane_collision_point := ray.position + t*ray.direction

    frac := hex.world_to_hex(plane_collision_point.xz)
    h := hex.fractional_to_hex(frac)
    return h, h in hex_board
}