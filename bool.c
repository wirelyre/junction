#include "runtime.h"

#include <assert.h>

// Reference-counted bool.

/*
    type Bool(True | False)
*/

Object bool_init(bool b)
{
    return b ? TRUE : FALSE;
}

bool bool_get(Object o)
{
    assert(o.kind == KIND_FALSE || o.kind == KIND_TRUE);
    return o.kind == KIND_TRUE;
}

const struct Module BOOL_MODULE = {
    .name = "Bool",
    .child_count = 0,
    .children = {},
};
