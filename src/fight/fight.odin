package fight

import "core:container/queue"
import "../hex"

board: hex.Board
kingdoms_by_capital: hex.KingdomsByCapital
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
    // hex.board_gen_hexagon(&board, 19)
    // hex.board_randomize(&board)
    // hex.board_gen_kingdoms(&board, &kingdoms_by_capital)
    hex.board_gen_island(&board, 20)

    deck_random(&deck, 20)
}

deinit :: proc() {
    delete(fighters)
    delete(board)
    delete(kingdoms_by_capital)

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

    legal_moves (board, id)
    path_finding(board, id)
}

deselect_fighter :: proc() {
    active_fighter = -1
    clear(&paths.legal)
    clear(&paths.came_from)
}