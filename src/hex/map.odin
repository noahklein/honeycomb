package hex

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

Map :: map[Hex]Tile

TileType :: enum u8 {
    Ground, Water,
}
Tile :: struct{
    type: TileType,
    capital: Maybe(Hex), // Capital city of this tile's kingdom.
}

KingdomsByCapital :: map[Hex]Kingdom

Kingdom :: struct {
    color: rl.Color,
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
        switch rand.float32() {
            case 0..<0.7: tile.type = .Ground
            case:         tile.type = .Water
        }
    }
}

TILE_COLORS := [TileType]rl.Color{
    .Ground = rl.BROWN,
    .Water  = rl.BLUE,
}

map_gen_kingdoms :: proc(m: ^Map, kingdoms: ^KingdomsByCapital) {
    kingdom_colors := [?]rl.Color{
        rl.RED, rl.ORANGE, rl.YELLOW, rl.GREEN, rl.VIOLET,
        rl.LIGHTGRAY, rl.PURPLE, rl.BLUE, rl.SKYBLUE, rl.PINK, rl.BLACK,
        rl.MAGENTA, rl.BROWN, rl.BEIGE,
    }

    for h, tile in m {
        if h in kingdoms do continue
        if _, ok := tile.capital.?; ok do continue

        kingdoms[h] = Kingdom{
            color = rand.choice(kingdom_colors[:]), // TODO: adjacent kingdoms should be different colors.
        }

        // Pick neighbors as cities.
        remaining := 4
        for dir in Direction {
            nbr := neighbor(h, dir)
            if nbr not_in m || nbr in kingdoms {
                continue
            }

            city := &m[nbr]
            if city.capital != nil {
                continue // City already belongs to a kingdom.
            }
            city.capital = h

            remaining -= 1
            if remaining <= 0 {
                break
            }
        }

        if remaining != 0 {
            fmt.printfln("Remaining %v", remaining)
        }
    }
}

map_kingdom_color :: proc(m: Map, kingdoms: KingdomsByCapital, h: Hex) -> rl.Color {
    capital := m[h].capital.? or_else h
    return kingdoms[capital].color
}