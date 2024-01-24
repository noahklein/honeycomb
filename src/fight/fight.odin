package fight

import "core:container/queue"
import "../hex"

level: hex.Map
side_to_move: Team
fighters: [dynamic]Fighter
active_fighter: int

deck: Deck

MOVES :: 4

Fighter :: struct {
    team: Team,
    hex: hex.Hex,
    moves_remaining: int,
}

Team :: enum u8 { Blue, Red }

init :: proc() {
    hex.map_gen_hexagon(&level, 10)
    hex.map_randomize(&level)

    deck_random(&deck, 20)
}

deinit :: proc() {
    delete(fighters)
    delete(level)

    delete(paths.legal)
    delete(paths.came_from)
    delete(paths.path)
    queue.destroy(&paths.queue)

    deck_deinit(deck)
}

end_turn :: proc() {
    side_to_move = .Blue if side_to_move == .Red else .Red
    deselect_fighter()

    for &f in fighters do f.moves_remaining = MOVES
}

set_active_fighter :: proc(id: int) {
    assert(fighters[id].team == side_to_move)
    active_fighter = id

    legal_moves (level, id)
    path_finding(level, id)
}

deselect_fighter :: proc() {
    active_fighter = -1
    clear(&paths.legal)
    clear(&paths.came_from)
}