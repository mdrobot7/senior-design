"""
Extract a range of bits from an integer.
"""
def bits(bitfield: int, top: int, bot: int) -> int:
    top_mask = ((2**(top + 1)) - 1)
    bot_mask = ((2**bot) - 1)
    mask = top_mask - bot_mask
    return (bitfield & mask) >> bot

"""
Convert an unsigned integer to a signed integer.
"""
def signed(unsigned_bits: int, size: int) -> int:
    if unsigned_bits >= (1 << (size - 1)):
        return unsigned_bits - (1 << size)
    else:
        return unsigned_bits

"""
Convert a signed integer to an unsigned integer.
"""
def unsigned(signed_bits: int, size: int) -> int:
    return signed_bits & ((1 << size) - 1)