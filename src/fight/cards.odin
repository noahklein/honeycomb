package fight

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

import "../ngui"

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

deck_update :: proc(deck: Deck) {
    if hovered := hand_hovered_card(deck); hovered != -1 && rl.IsMouseButtonPressed(.LEFT) {
        fmt.println("clicked", deck.hand[hovered])
    }
}

CARD_WIDTH  :: 86
CARD_HEIGHT :: CARD_WIDTH * 1.4

// @TEMP
CARD_COLORS := [CardId]rl.Color {
    .Warrior = rl.YELLOW,
    .Archer  = rl.ORANGE,
}

hand_hovered_card :: proc(deck: Deck) -> int {
    #reverse for _, i in deck.hand {
        rect := hand_card_rect(deck, i)
        if rl.CheckCollisionPointRec(rl.GetMousePosition(), rect) do return i
    }
    return -1
}

hand_card_rect :: proc(deck: Deck, index: int) -> rl.Rectangle {
    hand_size := f32(len(deck.hand))
    x := f32(rl.GetScreenWidth())/2 - hand_size*CARD_WIDTH / 2
    y := f32(rl.GetScreenHeight()) - CARD_HEIGHT - 2

    return rl.Rectangle{x + f32(index)*CARD_WIDTH*0.9, y, CARD_WIDTH, CARD_HEIGHT}
}

draw_cards_ui :: proc(deck: Deck) {
    draw_deck_pile_ui(10, len(deck.cards), rl.LIGHTGRAY)
    draw_deck_pile_ui(f32(rl.GetScreenWidth() - CARD_WIDTH - 10), len(deck.graveyard), rl.LIGHTGRAY)

    hovered_card := hand_hovered_card(deck)
    for card_id, i in deck.hand {
        rect := hand_card_rect(deck, i)
        color := CARD_COLORS[card_id]
        if i == hovered_card {
            color.r -= 50
            color.b += 200

            rect.y -= 15
        }
        rl.DrawRectangleRec(rect, color)
        rl.DrawRectangleLinesEx(rect, 2, rl.BLACK)

        {
            // Card label.
            label := fmt.ctprintf("%v", card_id)
            ngui.text_rect(rect, label, rl.BLACK, align = .Center)
        }
    }
}

draw_deck_pile_ui :: proc(x: f32, count: int, color: rl.Color) {
    deck_rect := rl.Rectangle{
        x, f32(rl.GetScreenHeight()) - CARD_HEIGHT - 5,
        CARD_WIDTH, CARD_HEIGHT,
    }
    rl.DrawRectangleRec(deck_rect, color)
    ngui.text_rect(deck_rect, fmt.ctprintf("%v", count), align = .Center)
}
