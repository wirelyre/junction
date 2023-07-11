#include "runtime.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// - Array of u8.
//   - (Backed by char[], but the C spec says char is at least u8/i8.)
// - Null bytes are safe!
// - The array is kept in-line with the metadata.
//   - So every value involves at most 1 allocation.

typedef struct Bytes {
    Value header;
    u32 len; // number of meaningful bytes in `contents`
    u32 cap; // capacity; always 0 or a power of 2
    char contents[];
} Bytes;

static u32 round_up_pow_2(u32 n)
{
    // Round up to nearest power of 2
    // from Hacker's Delight (Warren), second edition
    n -= 1;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    return n + 1;
}

Value *bytes_init(const char *s)
{
    u32 len = strlen(s);
    u32 cap = round_up_pow_2(len);

    Bytes *new = malloc(sizeof(Bytes) + cap);
    new->header.refcount = 1;
    new->header.tag = 0;
    new->len = len;
    new->cap = cap;
    memcpy(new->contents, s, len);

    return (Value *) new;
}

void bytes_append(Value **to_v, Value *from_v)
{
    Bytes *to = (Bytes *) *to_v;
    Bytes *from = (Bytes *) from_v;

    u32 new_len = to->len + from->len;

    // append in place?
    if (to->header.refcount == 1 && new_len <= to->cap) {
        memcpy(&to->contents[to->len], from->contents, from->len);
        to->len = new_len;

    } else {
        // allocate
        u32 new_cap = round_up_pow_2(new_len);

        Bytes *new = malloc(sizeof(Bytes) + new_cap);
        new->header.refcount = 1;
        new->header.tag = 0;
        new->len = new_len;
        new->cap = new_cap;
        memcpy(new->contents, to->contents, to->len);
        memcpy(&new->contents[to->len], from->contents, from->len);

        decref(*to_v);
        *to_v = (Value *) new;
    }

    decref(from_v);
}

void bytes_print(Value *b_v)
{
    // print to stdout
    Bytes *b = (Bytes *) b_v;
    fwrite(b->contents, 1, b->len, stdout);
    decref(b_v);
}
