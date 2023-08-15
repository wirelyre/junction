#include "runtime.h"
#include "identifiers.h"

#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// - Array of u8.
//   - (Backed by char[], but the C spec says char is at least u8/i8.)
// - Null bytes are safe!
// - The array is kept in-line with the metadata.
//   - So every value involves at most 1 allocation.

/*
    type Bytes(...)

    impl Bytes {
        fn append(^self, other: Bytes) { ... }
        fn print(self) { ... }
    }
*/

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

Object obj_make_bytes(const char *s)
{
    u32 len = strlen(s);
    u32 cap = round_up_pow_2(len);

    struct Bytes *b = malloc(sizeof(struct Bytes) + cap);
    b->refcount = 1;
    b->len = len;
    b->cap = cap;
    memcpy(b->contents, s, len);

    dbg("[alloc Bytes: %p]\n", b);

    struct Object o = {
        .kind = KIND_BYTES,
        .bytes = b,
    };
    return o;
}

// fn append(^self, other: Bytes)
FN(bytes_append, "Bytes.append")
{
    assert(argc == 2);
    Object self = arg_ref_kind(args, KIND_BYTES); // self: Bytes
    Object from_ = arg_kind(args, KIND_BYTES);    // from_: Bytes

    struct Bytes *to = self.ref->bytes;
    struct Bytes *from = from_.bytes;

    u32 new_len = to->len + from->len;

    // append in place?
    if (to->refcount == 1 && new_len <= to->cap) {
        memcpy(&to->contents[to->len], from->contents, from->len);
        to->len = new_len;

    } else {
        // allocate
        u32 new_cap = round_up_pow_2(new_len);

        struct Bytes *new = malloc(sizeof(struct Bytes) + new_cap);
        new->refcount = 1;
        new->len = new_len;
        new->cap = new_cap;
        memcpy(new->contents, to->contents, to->len);
        memcpy(&new->contents[to->len], from->contents, from->len);

        dbg("[alloc Bytes: %p]\n", new);

        obj_decref(*self.ref);
        self.ref->kind = KIND_BYTES;
        self.ref->bytes = new;
    }

    obj_decref(from_);

    return UNIT;
}

// fn print(self)
FN(bytes_print, "Bytes.print")
{
    assert(argc == 1);
    Object self = arg_kind(args, KIND_BYTES); // self: Bytes
    fwrite(self.bytes->contents, 1, self.bytes->len, stdout);
    obj_decref(self);
    return UNIT;
}

const struct Module BYTES_MODULE = {
    .name = "Bytes",
    .child_count = 2,
    .children = {
        { .name = Id_append, .value = FN_OBJ(bytes_append) },
        { .name = Id_print,  .value = FN_OBJ(bytes_print)  },
    },
};
