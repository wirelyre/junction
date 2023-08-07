#include "runtime.h"
#include "identifiers.h"

#include <assert.h>
#include <stdlib.h>

/*
    type Array[T](...)

    impl Array[T] {
        fn get(self, idx: Num): T
        fn set(^self, idx: Num, val: T)
    }
*/

static struct Array *array_alloc(u16 len)
{
    struct Array *new = malloc(sizeof(struct Array) + len * sizeof(Object));
    new->refcount = 1;
    new->len = len;

    dbg("[alloc Array: %p]\n", new);

    return new;
}

// Array with `len` copies of `el`.
Object array_init(u16 len, Object el)
{
    if (el.kind == KIND_REF)
        fail("Array", "initialized with ref");
    if (el.kind == KIND_MODULE)
        fail("Array", "initialized with module");

    struct Array *a = array_alloc(len);

    for (u16 i = 0; i < len; i++) {
        a->contents[i] = incref(el);
    }

    struct Object o = {
        .kind = KIND_ARRAY,
        .array = a,
    };
    decref(el);
    return o;
}

static struct Array *array_dup(struct Array *old)
{
    struct Array *new = array_alloc(old->len);

    for (u16 i = 0; i < old->len; i++) {
        new->contents[i] = incref(old->contents[i]);
    }

    return new;
}

// fn get(self, idx: Num): T
static Object array_get(u32 argc, va_list *args)
{
    assert(argc == 2);
    Object self = va_arg(*args, Object);
    Object idx = va_arg(*args, Object);
    assert(self.kind == KIND_ARRAY);
    assert(idx.kind == KIND_NUM);

    assert(idx.num < self.array->len);

    Object ret = incref(self.array->contents[idx.num]);
    decref(self);
    // decref(idx);
    return ret;
}

// fn set(^self, idx: Num, val: T)
static Object array_set(u32 argc, va_list *args)
{
    assert(argc == 3);
    Object self = va_arg(*args, Object);
    Object idx = va_arg(*args, Object);
    Object val = va_arg(*args, Object);
    assert(self.kind == KIND_REF);
    assert(self.ref->kind == KIND_ARRAY);
    assert(idx.kind == KIND_NUM);
    assert(val.kind != KIND_REF && val.kind != KIND_MODULE);

    assert(idx.num < self.ref->array->len);

    // ensure unique ref
    if (self.ref->array->refcount > 1) {
        struct Array *new = array_dup(self.ref->array);
        decref(*self.ref);
        self.ref->kind = KIND_ARRAY;
        self.ref->array = new;
    }

    decref(self.ref->array->contents[idx.num]);
    self.ref->array->contents[idx.num] = val;

    // decref(idx);
    return UNIT;
}

const struct Module ARRAY_MODULE = {
    .name = "Array",
    .child_count = 2,
    .children = {
        { .name = Id_get, .f = array_get },
        { .name = Id_set, .f = array_set },
    },
};
