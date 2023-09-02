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
Object obj_make_array(u16 len, Object el)
{
    if (el.kind == KIND_REF)
        fail("Array", "initialized with ref");
    if (el.kind == KIND_MODULE)
        fail("Array", "initialized with module");

    struct Array *a = array_alloc(len);

    for (u16 i = 0; i < len; i++) {
        a->contents[i] = obj_incref(el);
    }

    struct Object o = {
        .kind = KIND_ARRAY,
        .array = a,
    };
    obj_decref(el);
    return o;
}

static struct Array *array_dup(struct Array *old)
{
    struct Array *new = array_alloc(old->len);

    for (u16 i = 0; i < old->len; i++) {
        new->contents[i] = obj_incref(old->contents[i]);
    }

    return new;
}

// fn get(self, idx: Num): T
FN(array_get, "Array.get")
{
    assert(argc == 2);
    Object self = arg_kind(args, KIND_ARRAY); // self: Array[T]
    Object idx = arg_kind(args, KIND_NUM);    // idx: Num

    assert(idx.num < self.array->len);

    Object ret = obj_incref(self.array->contents[idx.num]);
    obj_decref(self);
    // decref(idx);
    return ret;
}

// fn set(^self, idx: Num, val: T)
FN(array_set, "Array.set")
{
    assert(argc == 3);
    Object self = arg_ref_kind(args, KIND_ARRAY); // ^self: Array[T]
    Object idx = arg_kind(args, KIND_NUM);        // idx: Num
    Object val = arg_val(args);                   // val: (any)

    assert(idx.num < self.ref->array->len);

    // ensure unique ref
    if (self.ref->array->refcount > 1) {
        struct Array *new = array_dup(self.ref->array);
        obj_decref(*self.ref);
        self.ref->kind = KIND_ARRAY;
        self.ref->array = new;
    }

    obj_decref(self.ref->array->contents[idx.num]);
    self.ref->array->contents[idx.num] = val;

    // decref(idx);
    return UNIT;
}

const struct Module ARRAY_MODULE = {
    .name = "Array",
    .child_count = 2,
    .children = {
        { .name = Id_get, .value = FN_OBJ(array_get) },
        { .name = Id_set, .value = FN_OBJ(array_set) },
    },
};
