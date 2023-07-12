#include "runtime.h"
#include "identifiers.h"

#include <stdio.h>
#include <stdlib.h>

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

typedef struct Num {
    Value header;
    u64 num;
} Num;

static VTable vt;

Value *num_init(u64 num)
{
    Num *new = (Num *) value_alloc_raw(&vt, Id_Number, sizeof(Num));
    new->num = num;
    return (Value *) new;
}

// fn sub(self, rhs: Number) -> Number
Value *num_sub(Value **self, va_list *l)
{
    Num *lhs = (Num *) *self;
    Num *rhs = (Num *) va_arg(*l, Value *);
    u64 res = lhs->num - rhs->num;
    decref((Value *) rhs);
    return num_init(res);
}

// fn mul(self, rhs: Number) -> Number
Value *num_mul(Value **self, va_list *l)
{
    Num *lhs = (Num *) *self;
    Num *rhs = (Num *) va_arg(*l, Value *);
    u64 res = lhs->num * rhs->num;
    decref((Value *) rhs);
    return num_init(res);
}

// fn gt(self, rhs: Number) -> Bool
Value *num_gt(Value **self, va_list *l)
{
    Num *lhs = (Num *) *self;
    Num *rhs = (Num *) va_arg(*l, Value *);
    bool res = lhs->num > rhs->num;
    decref((Value *) rhs);
    return bool_init(res);
}

// fn gt(self, ^b: Bytes)
Value *num_fmt(Value **self, va_list *l)
{
    Num *n = (Num *) *self;
    Value **b = va_arg(*l, Value **);
    char buf[21] = {0}; // fully zeroed
    sprintf(buf, "%"PRIu64, n->num);
    // the maximum u64 is 18446744073709551615, 20 digits
    method_r(b, Id_append, bytes_init(buf));
    return NULL;
}

static VTable vt = {
    .entry_count = 4,
    .entries = {
        { .name = Id_sub, .m = num_sub },
        { .name = Id_mul, .m = num_mul },
        { .name = Id_gt, .m = num_gt },
        { .name = Id_fmt, .m = num_fmt },
    },
};
