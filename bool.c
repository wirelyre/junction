#include "runtime.h"
#include "identifiers.h"

#include <assert.h>

// Reference-counted bool.

/*
    type Bool(True | False)
*/

static const struct Module BOOL_MODULE;
static const struct Data TRUE_DATA;
static const struct Data FALSE_DATA;

Object bool_init(bool b)
{
    Object new = {
        .kind = KIND_GLOBAL,
        .global = b ? &TRUE_DATA : &FALSE_DATA,
    };
    return new;
}

bool bool_get(Object o)
{
    assert(o.kind == KIND_GLOBAL);
    assert(o.global->module == &BOOL_MODULE);
    return o.global->tag == Id_True;
}

static const struct Module BOOL_MODULE = {
    .name = "Bool",
    .child_count = 0,
    .children = {},
};

static const struct Data TRUE_DATA = {
    .module = &BOOL_MODULE,
    .refcount = 1,
    .tag = Id_True,
};

static const struct Data FALSE_DATA = {
    .module = &BOOL_MODULE,
    .refcount = 1,
    .tag = Id_False,
};
