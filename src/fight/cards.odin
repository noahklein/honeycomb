package fight

import "core:math/rand"

MAX_HAND_SIZE :: 10

Deck :: struct{
    cards, hand, graveyard: [dynamic]CardId,
}

CardId :: enum{
    Warrior,
    Archer,
}

deck_deinit :: proc(deck: Deck) {
    delete(deck.cards)
    delete(deck.hand)
    delete(deck.graveyard)
}

deck_draw :: proc(deck: ^Deck) {
    top_card, ok := pop_safe(&deck.cards)
    if !ok {
        // @TODO: damage player to speed up their demise.
        return
    }

    if len(deck.hand) == MAX_HAND_SIZE {
        append(&deck.graveyard, top_card)
    } else {
        append(&deck.hand, top_card)
    }
}

deck_random :: proc(deck: ^Deck, size: int) {
    clear(&deck.cards)
    reserve(&deck.cards, size)
    for _ in 0..<size {
        card := CardId(rand.int_max(len(CardId)))
        append(&deck.cards, card)
    }
}