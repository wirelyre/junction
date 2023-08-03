#include "runtime.h"
#include "identifiers.h"

#include <assert.h>
#include <stdio.h>
#include <string.h>

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

static TypeInfo info;

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

    Value *new = value_alloc(&info, sizeof(Value) + cap);
    new->bytes.len = len;
    new->bytes.cap = cap;
    memcpy(new->bytes.contents, s, len);

    return (Value *) new;
}

// fn append(^self, other: Bytes)
static Value *bytes_append(Value **self, va_list *ap)
{
    Value *to = *self;
    Value *from = va_arg(*ap, Value *);

    assert(to->info == &info);
    assert(from->info == &info);

    u32 new_len = to->bytes.len + from->bytes.len;

    // append in place?
    if (to->refcount == 1 && new_len <= to->bytes.cap) {
        memcpy(&to->bytes.contents[to->bytes.len], from->bytes.contents, from->bytes.len);
        to->bytes.len = new_len;

    } else {
        // allocate
        u32 new_cap = round_up_pow_2(new_len);

        Value *new = value_alloc(&info, sizeof(Value) + new_cap);
        new->bytes.len = new_len;
        new->bytes.cap = new_cap;
        memcpy(new->bytes.contents, to->bytes.contents, to->bytes.len);
        memcpy(&new->bytes.contents[to->bytes.len], from->bytes.contents, from->bytes.len);

        decref(*self);
        *self = (Value *) new;
    }

    decref((Value *) from);

    return NULL;
}

// fn print(self)
static Value *bytes_print(Value **self, va_list *ap)
{
    // print to stdout
    Value *b = *self;
    assert(b->info == &info);
    fwrite(b->bytes.contents, 1, b->bytes.len, stdout);
    return NULL;
}

static TypeInfo info = {
    .name = "Bytes",
    .method_count = 2,
    .methods = {
        { .name = Id_append, .m = bytes_append },
        { .name = Id_print,  .m = bytes_print },
    },
};
