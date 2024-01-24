package hex

import "core:math/linalg"
import rl "vendor:raylib"

SQRT_THREE :: linalg.SQRT_THREE

Layout :: struct {
    orientation: Orientation,
    origin, size: rl.Vector2,
}

layout := Layout{
    orientation = POINTY,
    size = 1,
}

Orientation :: struct {
    forward, inverse: matrix[2, 2]f32,
    start_angle: f32, // In multiples of 60°.
}

POINTY :: Orientation{
    forward = {SQRT_THREE,  SQRT_THREE/2, 0, 3.0/2},
    inverse = {SQRT_THREE/3,      -1.0/3, 0, 2.0/3},
    start_angle = 0.5,
}

@(require_results)
hex_to_world :: proc(hex: Hex) -> rl.Vector2 {
    M := layout.orientation.forward
    p := M * linalg.array_cast(hex.xy, f32)

    return p*layout.size + layout.origin
}

FractionalHex :: rl.Vector3

@(require_results)
world_to_hex :: proc(point: rl.Vector2) -> FractionalHex {
    M := layout.orientation.inverse
    pt := (point - layout.origin) / layout.size

    p := M * pt
    return {p.x, p.y, -p.x-p.y}
}

@(require_results)
fractional_to_hex :: proc(frac: FractionalHex) -> Hex {
    rounded := linalg.round(frac)
    diff := linalg.abs(rounded - frac)

    h := Hex(linalg.array_cast(rounded, int))
    if diff.x > diff.y && diff.x > diff.z {
        h.x = -h.y - h.z
    } else if diff.y > diff.z {
        h.y = -h.x - h.z
    } else {
        h.z = -h.x - h.y
    }

    return h
}