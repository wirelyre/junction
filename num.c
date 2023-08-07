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
static FN(num_sub)
{
    assert(argc == 2);
    Object lhs = arg_kind(args, KIND_NUM); // lhs: Num
    Object rhs = arg_kind(args, KIND_NUM); // rhs: Num

    Object ret = {
        .kind = KIND_NUM,
        .num = lhs.num - rhs.num,
    };
    // decref(lhs);
    // decref(rhs);
    return ret;
}

// fn mul(self, rhs: Num) -> Num
static FN(num_mul)
{
    assert(argc == 2);
    Object lhs = arg_kind(args, KIND_NUM); // lhs: Num
    Object rhs = arg_kind(args, KIND_NUM); // rhs: Num

    Object ret = {
        .kind = KIND_NUM,
        .num = lhs.num * rhs.num,
    };
    // decref(lhs);
    // decref(rhs);
    return ret;
}

// fn gt(self, rhs: Num) -> Bool
static FN(num_gt)
{
    assert(argc == 2);
    Object lhs = arg_kind(args, KIND_NUM); // lhs: Num
    Object rhs = arg_kind(args, KIND_NUM); // rhs: Num

    // decref(lhs);
    // decref(rhs);
    return bool_init(lhs.num > rhs.num);
}

// fn fmt(self, ^b: Bytes)
static FN(num_fmt)
{
    assert(argc == 2);
    Object n = arg_kind(args, KIND_NUM);       // n: Num
    Object b = arg_ref_kind(args, KIND_BYTES); // ^b: Bytes

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
