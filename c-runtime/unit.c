#include "runtime.h"
#include "identifiers.h"

/*
    type Unit
*/

static const struct Module UNIT_MODULE = {
    .name = "Unit",
    .child_count = 0,
    .children = {},
};

static const struct Data UNIT_DATA = {
    .module = &UNIT_MODULE,
    .refcount = 1,
    .tag = Id_Unit,
};

const Object UNIT = {
    .kind = KIND_GLOBAL,
    .global = &UNIT_DATA,
};
