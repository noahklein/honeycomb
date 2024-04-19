package olympus

Domain :: enum u8 {
    Ocean,
    Sky,
    Earth,
    Fire,

    Forest,
    River,

    Harvest,
    Music,
    Wine,

    Love,
    Death,
}

God :: struct {
    domains: bit_set[Domain],
}

NUM_GODS :: 6

gods : [NUM_GODS]God