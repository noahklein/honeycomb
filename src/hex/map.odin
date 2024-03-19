package hex

import "core:math/rand"
import rl "vendor:raylib"

Board :: map[Hex]Tile

TileType :: enum u8 {
    Ground, Water,
}
Tile :: struct{
    type: TileType,
    capital: Hex, // Capital city of this tile's kingdom.
}

KingdomsByCapital :: map[Hex]Kingdom

Kingdom :: struct {
    color: rl.Color,
}

board_gen_triangle :: proc(board: ^Board, size: int) {
    clear(board)
    reserve(board, size * (size - 1) / 2)

    for q in 0..<size {
        for r in size - q..<size {
            board[hex(q, r)] = {}
        }
    }
}

board_gen_hexagon :: proc(board: ^Board, radius: int) {
    clear(board)
    reserve(board, radius * (radius - 1) / 2)

    for q in -radius..=radius {
        r1 := max(-radius, -q - radius)
        r2 := min( radius, -q + radius)

        for r in r1..=r2 {
            board[hex(q, r)] = {}
        }
    }
}

board_randomize :: proc(m: ^Board) {
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

board_gen_kingdoms :: proc(board: ^Board, kingdoms: ^KingdomsByCapital) {
    // Erect capitals greedily.
    for h, tile in board {
        if h in kingdoms || tile.capital != 0 do continue

        tile.capital = h
        kingdoms[h] = Kingdom{color = rl.BLACK} // Colors will be assigned later.

        // Pick neighbors as cities.
        remaining := 4
        for dir in Direction {
            nbr := neighbor(h, dir)
            if nbr not_in board || nbr in kingdoms {
                continue
            }

            city := &board[nbr]
            if city.capital != 0 do continue // City already belongs to another kingdom.

            city.capital = h

            remaining -= 1
            if remaining <= 0 {
                break
            }
        }
    }

    {
        // Kingdoms have been established. Assign colors such that no neighbors share a color.
        neighboring_capitals := make(map[Hex]struct{}, 10, context.temp_allocator)
        COLORS := [?]rl.Color{rl.RED, rl.GREEN, rl.BLUE, rl.YELLOW, rl.PURPLE, rl.ORANGE}

        for capital, &kingdom in kingdoms {
            clear(&neighboring_capitals)

            // Wasteful linear search to find cities in this kingdom.
            for h, tile in board {
                if tile.capital == capital {
                    for dir in Direction {
                        nbr := neighbor(h, dir)
                        if nbr not_in board do continue

                        nbr_capital := board[nbr].capital
                        neighboring_capitals[nbr_capital] = {}
                    }
                }
            }

            color_loop: for color in COLORS {
                for nbr_cap in neighboring_capitals {
                    if kingdoms[nbr_cap].color == color do continue color_loop
                }
                kingdom.color = color
                break
            }
        }
    }
}

board_kingdom_color :: proc(board: Board, kingdoms: KingdomsByCapital, h: Hex) -> rl.Color {
    capital := board[h].capital
    return kingdoms[capital].color
}