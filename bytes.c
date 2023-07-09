#include "runtime.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// - Array of u8.
//   - (Backed by char[], but the C spec says char is at least u8/i8.)
// - Null bytes are safe!
// - The array is kept in-line with the metadata.
//   - So every value involves at most 1 allocation.

struct Bytes {
    u32 refcount;
    u32 len; // number of meaningful bytes in `contents`
    u32 cap; // capacity; always 0 or a power of 2
    char contents[];
};

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

Bytes *bytes_init(const char *s)
{
    u32 len = strlen(s);
    u32 cap = round_up_pow_2(len);

    Bytes *b = malloc(sizeof(Bytes) + cap);
    b->refcount = 1;
    b->len = len;
    b->cap = cap;
    memcpy(b->contents, s, len);

    return b;
}

Bytes *bytes_incref(Bytes *b)
{
    b->refcount++;
    return b;
}

void bytes_decref(Bytes *b)
{
    b->refcount--;
    if (b->refcount == 0)
        free(b);
}



void bytes_print(Bytes *b)
{
    // print to stdout
    fwrite(b->contents, 1, b->len, stdout);
    bytes_decref(b);
}

void bytes_append(Bytes **to, Bytes *from)
{
    u32 new_len = (*to)->len + from->len;

    // append in place?
    if ((*to)->refcount == 1 && new_len <= (*to)->cap) {
        memcpy(&(*to)->contents[(*to)->len], from->contents, from->len);
        (*to)->len = new_len;

    } else {
        // allocate
        u32 new_cap = round_up_pow_2(new_len);

        Bytes *b = malloc(sizeof(Bytes) + new_cap);
        b->refcount = 1;
        b->len = new_len;
        b->cap = new_cap;
        memcpy(b->contents, (*to)->contents, (*to)->len);
        memcpy(&b->contents[(*to)->len], from->contents, from->len);

        bytes_decref(*to);
        *to = b;
    }

    bytes_decref(from);
}
