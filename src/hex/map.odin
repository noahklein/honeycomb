package hex

import "core:math/rand"
import rl "vendor:raylib"

Map :: map[Hex]Tile

TileType :: enum u8 {
    Ground, Water,
}
Tile :: struct{
    type: TileType,
}

map_gen_triangle :: proc(m: ^Map, size: int) {
    clear(m)
    reserve(m, size * (size - 1) / 2)

    for q in 0..<size {
        for r in size - q..<size {
            m[hex(q, r)] = {}
        }
    }
}

map_gen_hexagon :: proc(m: ^Map, radius: int) {
    clear(m)
    reserve(m, radius * (radius - 1) / 2)

    for q in -radius..=radius {
        r1 := max(-radius, -q - radius)
        r2 := min( radius, -q + radius)

        for r in r1..=r2 {
            m[hex(q, r)] = {}
        }
    }
}

map_randomize :: proc(m: ^Map) {
    for h, &tile in m do if h != 0 {
        tile.type = TileType(rand.int_max(len(TileType)))
    }
}

TILE_COLORS := [TileType]rl.Color{
    .Ground = rl.BROWN,
    .Water  = rl.BLUE,
}
