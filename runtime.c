#include "runtime.h"

#include <stdlib.h>

Value *value_alloc(VTable *vt, u32 tag)
{
    return value_alloc_raw(vt, tag, sizeof(Value));
}

Value *value_alloc_raw(VTable *vt, u32 tag, u32 size)
{
    Value *v = malloc(size);
    v->vtable = vt;
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
    // TODO: if (v == NULL) return;
    v->refcount--;
    if (v->refcount == 0)
        free(v);
}

static Method method_lookup(Value *v, u32 name)
{
    VTable *vt = v->vtable;

    for (u32 i = 0; i < vt->entry_count; i++) {
        if (vt->entries[i].name == name) {
            return vt->entries[i].m;
        }
    }

    return NULL;
}

Value *method_v(Value *self, u32 name, ...)
{
    va_list ap;
    va_start(ap, name);
    Value *res = method_lookup(self, name)(&self, &ap);
    va_end(ap);

    decref(self);
    return res;
}

Value *method_r(Value **self, u32 name, ...)
{
    va_list ap;
    va_start(ap, name);
    Value *res = method_lookup(*self, name)(self, &ap);
    va_end(ap);

    return res;
}
