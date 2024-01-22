package main

import "core:time"
import rl "vendor:raylib"

import "ngui"
import "rlutil"

draw_gui :: proc(camera: ^rl.Camera) {
    ngui.update()


    if ngui.begin_panel("Game", {0, 0, 400, 0}) {
        if ngui.flex_row({0.2, 0.2, 0.3, 0.3}) {
            ngui.text("Camera")
            ngui.float(&camera.fovy, min = 20, max = 160, label = "Fovy")
            ngui.vec3(&camera.position, label = "Position")
            ngui.vec3(&camera.target, label = "Target")
        }

        if ngui.flex_row({1}) {
            if ngui.graph_begin("Time", 256, lower = 0, upper = f32(time.Second) / 60) {
                ngui.graph_line("Update", rlutil.profile_duration("update"), rl.SKYBLUE)
                ngui.graph_line("Draw", rlutil.profile_duration("draw"), rl.RED)
            }
        }
    }

    rl.DrawFPS(rl.GetScreenWidth() - 80, 0)
}