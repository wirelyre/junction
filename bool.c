#include "runtime.h"
#include "identifiers.h"

#include <assert.h>
#include <stdlib.h>

// Reference-counted bool.

/*
    type Bool(True | False)
 */

// right now Id_False is not guaranteed to be 0
// it could be though

static VTable vt;

Value *bool_init(bool b)
{
    u32 tag = b ? Id_True : Id_False;
    return value_alloc(&vt, tag);
}

bool bool_get(Value *b)
{
    assert(b->tag == Id_True || b->tag == Id_False);
    bool res = b->tag == Id_True;
    decref(b);
    return res;
}

static VTable vt = {
    .entry_count = 0,
    .entries = {},
};
