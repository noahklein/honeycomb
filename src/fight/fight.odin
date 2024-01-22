package fight

import "core:container/queue"
import "../hex"

fighters: [dynamic]Fighter

Fighter :: struct {
    hex: hex.Hex,
    moves_remaining: int,
}

init :: proc() {}

deinit :: proc() {
    delete(fighters)
    delete(paths.legal)
    delete(paths.came_from)
    queue.destroy(&paths.queue)
}