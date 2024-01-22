package fight

import "../hex"
import "core:container/queue"

// Path-finding results and re-used storage.
paths : PathFinding

PathFinding :: struct {
    legal    : map[hex.Hex]struct{},
    came_from: map[hex.Hex]Maybe(hex.Hex),

    queue: queue.Queue(hex.Hex),
}

legal_moves :: proc(level: hex.Map, fighter_id: int) {
    clear(&paths.legal)
    f := fighters[fighter_id]
    _legal_moves(level, f.hex, f.moves_remaining)
}

@(private="file")
_legal_moves :: proc(level: hex.Map, tile: hex.Hex, depth: int) {
    if depth <= 0 || tile not_in level {
        return
    }

    paths.legal[tile] = {}
    for dir in hex.Direction {
        neighbor := hex.neighbor(tile, dir)
        _legal_moves(level, neighbor, depth - 1)
    }
}

path_finding :: proc(level: hex.Map, fighter_id: int) {
    start := fighters[fighter_id].hex
    queue.clear(&paths.queue)
    queue.push(&paths.queue, start)

    clear(&paths.came_from)
    paths.came_from[start] = nil

    for queue.len(paths.queue) != 0 {
        tile := queue.pop_front(&paths.queue)
        for dir in hex.Direction {
            neighbor := hex.neighbor(tile, dir)
            if neighbor in paths.came_from {
                continue
            }

            paths.came_from[neighbor] = tile
        }
    }
}