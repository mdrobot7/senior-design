from typing import Iterable

"""
Returns True if all elements in a list/array are
equal, False otherwise.
"""
def all_equal(list: Iterable) -> bool:
    # This is both beautiful and disgusting
    return len(set(list)) <= 1