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

FN(bool_not, "Bool.not")
{
    assert(argc == 1);
    Object self = arg_val(args);
    return bool_init(!bool_get(self));
}

FN(bool_and, "Bool.and")
{
    assert(argc == 2);
    Object lhs = arg_val(args);
    Object rhs = arg_val(args);
    return bool_init(bool_get(lhs) & bool_get(rhs));
}

FN(bool_or, "Bool.or")
{
    assert(argc == 2);
    Object lhs = arg_val(args);
    Object rhs = arg_val(args);
    return bool_init(bool_get(lhs) | bool_get(rhs));
}

FN(bool_xor, "Bool.xor")
{
    assert(argc == 2);
    Object lhs = arg_val(args);
    Object rhs = arg_val(args);
    return bool_init(bool_get(lhs) ^ bool_get(rhs));
}

static const struct Module BOOL_MODULE = {
    .name = "Bool",
    .child_count = 4,
    .children = {
        { .name = Id_not, .obj = FN_OBJ(bool_not) },
        { .name = Id_and, .obj = FN_OBJ(bool_and) },
        { .name = Id_or,  .obj = FN_OBJ(bool_or)  },
        { .name = Id_xor, .obj = FN_OBJ(bool_xor) },
    },
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
