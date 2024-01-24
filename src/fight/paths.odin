package fight

import "../hex"
import "core:container/queue"

// Path-finding results and re-used storage.
paths : PathFinding

PathFinding :: struct {
    legal    : map[hex.Hex]struct{},
    came_from: map[hex.Hex]Maybe(hex.Hex),

    path : [dynamic]hex.Hex,
    queue: queue.Queue(hex.Hex),
}


legal_moves :: proc(level: hex.Map, fighter_id: int) {
    fighter := fighters[fighter_id]
    start, moves := fighter.hex, fighter.moves_remaining

    clear(&paths.legal)
    paths.legal[start] = {}
    defer delete_key(&paths.legal, start) // Fighter can't move to its own tile.

    // Flow-fileld BFS. Visits nodes layer-by-layer.
    visiting  := make([dynamic]hex.Hex, context.temp_allocator) // The nodes on this layer.
    neighbors := make([dynamic]hex.Hex, context.temp_allocator) // Their neighbors.
    append(&neighbors, start)
    for _ in 1..=moves {
        // Next layer; swap buffers.
        visiting, neighbors = neighbors, visiting
        clear(&neighbors)

        for h in visiting do for dir in hex.Direction {
            neighbor := hex.neighbor(h, dir)
            if neighbor in paths.legal {
                continue
            }
            if neighbor not_in level || level[neighbor].type == .Water {
                continue
            }

            paths.legal[neighbor] = {}
            append(&neighbors, neighbor)
        }
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
            if neighbor not_in paths.legal {
                continue
            }
            if neighbor in paths.came_from {
                continue
            }

            paths.came_from[neighbor] = tile
            queue.push(&paths.queue, neighbor)
        }
    }
}

path_update :: proc(dest: hex.Hex) {
    clear(&paths.path)

    end := dest
    for {
        from := paths.came_from[end] or_break
        append(&paths.path, end)
        end = from.(hex.Hex) or_break
    }

    pop_safe(&paths.path) // Remove fighter's tile from path.
}