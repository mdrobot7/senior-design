from typing import Iterable

def bits(bitfield, top, bot) -> int:
    top_mask = ((2**(top + 1)) - 1)
    bot_mask = ((2**bot) - 1)
    mask = top_mask - bot_mask
    return (bitfield & mask) >> bot

def signed(unsigned_bits, size) -> int:
    if unsigned_bits >= (1 << (size - 1)):
        return unsigned_bits - (1 << size)
    else:
        return unsigned_bits

def all_equal(list: Iterable) -> bool:
    # This is both beautiful and disgusting
    return len(set(list)) <= 1