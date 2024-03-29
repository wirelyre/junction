#include "runtime.h"
#include "identifiers.h"

#include <assert.h>
#include <stdio.h>

// Reference-counted u64.

/*
    type Number(...)

    impl Number (Arithmetic, Boolean, Gt, Fmt) {
        fn add(self, rhs: Number) -> Number
        fn sub(self, rhs: Number) -> Number
        fn mul(self, rhs: Number) -> Number
        fn div(self, rhs: Number) -> Number

        fn not(self) -> Number
        fn and(self, rhs: Number) -> Number
        fn or (self, rhs: Number) -> Number
        fn xor(self, rhs: Number) -> Number

        fn gt (self, rhs: Number) -> Bool

        fn fmt(self, ^b: Bytes)
    }
*/

Object obj_make_num(u64 num)
{
    Object new = {
        .kind = KIND_NUM,
        .num = num,
    };
    return new;
}

#define NUM_BINOP(op, expr)                    \
    FN(num_##op, "Num."#op)                    \
    {                                          \
        assert(argc == 2);                     \
        Object lhs = arg_kind(args, KIND_NUM); \
        Object rhs = arg_kind(args, KIND_NUM); \
        return expr;                           \
    }

    NUM_BINOP(add, obj_make_num(lhs.num + rhs.num))
    NUM_BINOP(sub, obj_make_num(lhs.num - rhs.num))
    NUM_BINOP(mul, obj_make_num(lhs.num * rhs.num))
    // NUM_BINOP(div, num_init(lhs.num / rhs.num))

    // NUM_UNOP(not, num_init(~self.num))
    NUM_BINOP(and, obj_make_num(lhs.num & rhs.num))
    NUM_BINOP(or,  obj_make_num(lhs.num | rhs.num))
    NUM_BINOP(xor, obj_make_num(lhs.num ^ rhs.num))

    NUM_BINOP(gt, obj_make_bool(lhs.num > rhs.num))

#undef NUM_BINOP

// fn div(self, rhs: Num) -> Num
FN(num_div, "Num.div")
{
    assert(argc == 2);
    Object lhs = arg_kind(args, KIND_NUM); // lhs: Num
    Object rhs = arg_kind(args, KIND_NUM); // rhs: Num
    assert(rhs.num != 0); // TODO: consider returning -1, or fail(...)
    return obj_make_num(lhs.num / rhs.num);
}

// fn not(self) -> Num
FN(num_not, "Num.not")
{
    assert(argc == 1);
    Object self = arg_kind(args, KIND_NUM); // self: Num
    return obj_make_num(~self.num);
}

// fn fmt(self, ^b: Bytes)
FN(num_fmt, "Num.fmt")
{
    assert(argc == 2);
    Object n = arg_kind(args, KIND_NUM);       // n: Num
    Object b = arg_ref_kind(args, KIND_BYTES); // ^b: Bytes

    char buf[21] = {0}; // fully zeroed
    sprintf(buf, "%"PRIu64, n.num);
    // the maximum u64 is 18446744073709551615, 20 digits
    method(Id_append, b, obj_make_bytes(buf));

    // decref(n)
    return UNIT;
}

const struct Module NUM_MODULE = {
    .name = "Num",
    .child_count = 10,
    .children = {
        { .name = Id_add, .value = FN_OBJ(num_add) },
        { .name = Id_sub, .value = FN_OBJ(num_sub) },
        { .name = Id_mul, .value = FN_OBJ(num_mul) },
        { .name = Id_div, .value = FN_OBJ(num_div) },

        { .name = Id_not, .value = FN_OBJ(num_not) },
        { .name = Id_and, .value = FN_OBJ(num_and) },
        { .name = Id_or,  .value = FN_OBJ(num_or)  },
        { .name = Id_xor, .value = FN_OBJ(num_xor) },

        { .name = Id_gt,  .value = FN_OBJ(num_gt)  },

        { .name = Id_fmt, .value = FN_OBJ(num_fmt) },
    },
};
