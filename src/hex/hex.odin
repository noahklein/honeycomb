package hex

Hex :: distinct [3]int // Cube coordinate on a hex grid.

Direction :: enum u8 {
    // Counter-clockwise, for pointy tip hexes.
    E, NE, NW, W, SW, SE,
}

DIRECTIONS := [Direction]Hex{
    .E = {1, 0, -1}, .NE = {1, -1, 0}, .NW = {0, -1, 1},
    .W = {-1, 0, 1}, .SW = {-1, 1, 0}, .SE = {0, 1, -1},
}

direction :: #force_inline proc(dir: Direction) -> Hex { return DIRECTIONS[dir] }

@(require_results)
clockwise :: #force_inline proc(dir: Direction) -> Direction {
    return Direction((int(dir) + 5) % 6)
}
@(require_results)
counterclockwise :: #force_inline proc(dir: Direction) -> Direction {
    return Direction((int(dir) + 1) % 6)
}

@(require_results)
hex :: proc(q, r: int) -> Hex {
    return Hex{q, r, -q-r}
}

@(require_results)
length :: proc(h: Hex) -> int {
    return (abs(h.x) + abs(h.y) + abs(h.z)) / 2
}

@(require_results)
distance :: proc(a, b: Hex) -> int {
    return length(a - b)
}

@(require_results)
neighbor :: proc(h: Hex, dir: Direction) -> Hex {
    return h + direction(dir)
}