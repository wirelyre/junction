#include "runtime.h"

#include <stdlib.h>

Value *value_alloc(u32 tag)
{
    Value *v = malloc(sizeof(Value));
    v->refcount = 1;
    v->tag = tag;
    return v;
}

Value *incref(Value *v)
{
    v->refcount++;
    // TODO: if (v->refcount == 0) panic("reference count overflowed");
    return v;
}

void decref(Value *v)
{
    v->refcount--;
    if (v->refcount == 0)
        free(v);
}
