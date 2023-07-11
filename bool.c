#include "runtime.h"

#include <assert.h>
#include <stdlib.h>

// Reference-counted bool.

enum BoolTag {
    // right now, this shouldn't rely on TAG_False == 0 and TAG_True != 0
    // it might later because that seems like a good idea
    TAG_False = 1,
    TAG_True = 2,
};

Value *bool_init(bool b)
{
    u32 tag = b ? TAG_True : TAG_False;
    return value_alloc(tag);
}

bool bool_get(Value *b)
{
    assert(b->tag == TAG_True || b->tag == TAG_False);
    bool res = b->tag == TAG_True;
    decref(b);
    return res;
}
