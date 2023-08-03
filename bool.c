#include "runtime.h"
#include "identifiers.h"

#include <assert.h>

// Reference-counted bool.

/*
    type Bool(True | False)
 */

static TypeInfo info;

bool bool_get(Value *b)
{
    assert(b->info == &info);
    bool res = b == &TRUE;
    decref(b);
    return res;
}

static TypeInfo info = {
    .name = "Bool",
    .method_count = 0,
    .methods = {},
};

Value TRUE = {
    .info = &info,
    .refcount = 1,
    .data = { .tag = Id_True },
};

Value FALSE = {
    .info = &info,
    .refcount = 1,
    .data = { .tag = Id_False },
};
