#include "runtime.h"
#include "identifiers.h"

#include <assert.h>
#include <stdio.h>

// Reference-counted u64.

/*
    type Number(...)

    impl Number (Sub, Mul, Gt, Fmt) {
        fn sub(self, rhs: Number) -> Number
        fn mul(self, rhs: Number) -> Number
        fn gt (self, rhs: Number) -> Bool
        fn fmt(self, ^b: Bytes)
    }
*/

Object num_init(u64 num)
{
    Object new = {
        .kind = KIND_NUM,
        .num = num,
    };
    return new;
}

// fn sub(self, rhs: Num) -> Num
static Object num_sub(u32 argc, va_list *args)
{
    assert(argc == 2);
    Object lhs = va_arg(*args, Object);
    Object rhs = va_arg(*args, Object);
    assert(lhs.kind == KIND_NUM);
    assert(rhs.kind == KIND_NUM);

    Object ret = {
        .kind = KIND_NUM,
        .num = lhs.num - rhs.num,
    };
    // decref(lhs);
    // decref(rhs);
    return ret;
}

// fn mul(self, rhs: Num) -> Num
static Object num_mul(u32 argc, va_list *args)
{
    assert(argc == 2);
    Object lhs = va_arg(*args, Object);
    Object rhs = va_arg(*args, Object);
    assert(lhs.kind == KIND_NUM);
    assert(rhs.kind == KIND_NUM);

    Object ret = {
        .kind = KIND_NUM,
        .num = lhs.num * rhs.num,
    };
    // decref(lhs);
    // decref(rhs);
    return ret;
}

// fn gt(self, rhs: Num) -> Bool
static Object num_gt(u32 argc, va_list *args)
{
    assert(argc == 2);
    Object lhs = va_arg(*args, Object);
    Object rhs = va_arg(*args, Object);
    assert(lhs.kind == KIND_NUM);
    assert(rhs.kind == KIND_NUM);

    // decref(lhs);
    // decref(rhs);
    return bool_init(lhs.num > rhs.num);
}

// fn fmt(self, ^b: Bytes)
static Object num_fmt(u32 argc, va_list *args)
{
    assert(argc == 2);
    Object n = va_arg(*args, Object);
    Object b = va_arg(*args, Object);
    assert(n.kind == KIND_NUM);
    assert(b.kind == KIND_REF);
    assert(b.ref->kind == KIND_BYTES);

    char buf[21] = {0}; // fully zeroed
    sprintf(buf, "%"PRIu64, n.num);
    // the maximum u64 is 18446744073709551615, 20 digits
    method(Id_append, b, bytes_init(buf));

    // decref(n)
    return UNIT;
}

const struct Module NUM_MODULE = {
    .name = "Num",
    .child_count = 4,
    .children = {
        { .name = Id_sub, .f = num_sub },
        { .name = Id_mul, .f = num_mul },
        { .name = Id_gt,  .f = num_gt  },
        { .name = Id_fmt, .f = num_fmt },
    },
};
