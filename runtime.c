#include "runtime.h"

#include <stdlib.h>

#ifdef DEBUG
    #include "identifiers.h"
    #include <stdio.h>
    #define DBG(format, ...) printf("\033[2m"format"\033[0m", __VA_ARGS__)
#else
    #define DBG(...)
#endif

Value *value_alloc(TypeInfo *info, u32 size)
{
    Value *new = malloc(sizeof(Value) + size);
    new->info = info;
    new->refcount = 1;
    DBG("[alloc  %s: %p]\n", info->name, new);
    return new;
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
    if (v->refcount == 0) {
        DBG("[free   %s: %p]\n", v->info->name, v);
        free(v);
    }
}

static Method method_lookup(Value *v, u32 name)
{
    TypeInfo *info = v->info;

    for (u32 i = 0; i < info->method_count; i++) {
        if (info->methods[i].name == name) {
            return info->methods[i].m;
        }
    }

    return NULL;
}

Value *method_v(Value *self, u32 name, ...)
{
    DBG("[method %s(self: %s, ...): %p]\n",
        identifiers[name], self->info->name, method_lookup(self, name));

    va_list ap;
    va_start(ap, name);
    Value *res = method_lookup(self, name)(&self, &ap);
    va_end(ap);

    decref(self);
    return res;
}

Value *method_r(Value **self, u32 name, ...)
{
    DBG("[method %s(^self: %s, ...): %p]\n",
        identifiers[name], (*self)->info->name, method_lookup(*self, name));

    va_list ap;
    va_start(ap, name);
    Value *res = method_lookup(*self, name)(self, &ap);
    va_end(ap);

    return res;
}
