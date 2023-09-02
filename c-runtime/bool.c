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

Object obj_make_bool(bool b)
{
    Object new = {
        .kind = KIND_GLOBAL,
        .global = b ? &TRUE_DATA : &FALSE_DATA,
    };
    return new;
}

bool obj_get_bool(Object o)
{
    assert(o.kind == KIND_GLOBAL);
    assert(o.global->module == &BOOL_MODULE);
    return o.global->tag == Id_True;
}

FN(bool_not, "Bool.not")
{
    assert(argc == 1);
    Object self = arg_val(args);
    return obj_make_bool(!obj_get_bool(self));
}

FN(bool_and, "Bool.and")
{
    assert(argc == 2);
    Object lhs = arg_val(args);
    Object rhs = arg_val(args);
    return obj_make_bool(obj_get_bool(lhs) & obj_get_bool(rhs));
}

FN(bool_or, "Bool.or")
{
    assert(argc == 2);
    Object lhs = arg_val(args);
    Object rhs = arg_val(args);
    return obj_make_bool(obj_get_bool(lhs) | obj_get_bool(rhs));
}

FN(bool_xor, "Bool.xor")
{
    assert(argc == 2);
    Object lhs = arg_val(args);
    Object rhs = arg_val(args);
    return obj_make_bool(obj_get_bool(lhs) ^ obj_get_bool(rhs));
}

static const struct Module BOOL_MODULE = {
    .name = "Bool",
    .child_count = 4,
    .children = {
        { .name = Id_not, .value = FN_OBJ(bool_not) },
        { .name = Id_and, .value = FN_OBJ(bool_and) },
        { .name = Id_or,  .value = FN_OBJ(bool_or)  },
        { .name = Id_xor, .value = FN_OBJ(bool_xor) },
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
