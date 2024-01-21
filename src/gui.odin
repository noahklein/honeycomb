package main

import rl "vendor:raylib"
import "ngui"

tmp_vec2: rl.Vector2

draw_gui :: proc(camera: ^rl.Camera) {
    ngui.update()


    if ngui.begin_panel("Game", {0, 0, 400, 0}) {
        if ngui.flex_row({0.2, 0.2, 0.2, 0.3}) {
            ngui.text("Camera")
            ngui.float(&camera.fovy, min = 20, max = 160, label = "Fovy")

            ngui.vec2(&tmp_vec2, label = "Test")

            ngui.vec3(&camera.position, label = "Position")
        }
    }

}