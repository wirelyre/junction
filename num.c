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

static TypeInfo info;

Value *num_init(u64 num)
{
    Value *new = value_alloc(&info, 0);
    new->num = num;
    return new;
}

// fn sub(self, rhs: Number) -> Number
static Value *num_sub(Value **self, va_list *l)
{
    Value *lhs = *self;
    Value *rhs = va_arg(*l, Value *);

    assert(lhs->info == &info);
    assert(rhs->info == &info);

    u64 res = lhs->num - rhs->num;
    decref(rhs);
    return num_init(res);
}

// fn mul(self, rhs: Number) -> Number
static Value *num_mul(Value **self, va_list *l)
{
    Value *lhs = *self;
    Value *rhs = va_arg(*l, Value *);

    assert(lhs->info == &info);
    assert(rhs->info == &info);

    u64 res = lhs->num * rhs->num;
    decref(rhs);
    return num_init(res);
}

// fn gt(self, rhs: Number) -> Bool
static Value *num_gt(Value **self, va_list *l)
{
    Value *lhs = *self;
    Value *rhs = va_arg(*l, Value *);

    assert(lhs->info == &info);
    assert(rhs->info == &info);

    bool res = lhs->num > rhs->num;
    decref(rhs);
    return res ? incref(&TRUE) : incref(&FALSE);
}

// fn fmt(self, ^b: Bytes)
static Value *num_fmt(Value **self, va_list *l)
{
    Value *n = *self;
    Value **b = va_arg(*l, Value **);
    char buf[21] = {0}; // fully zeroed
    sprintf(buf, "%"PRIu64, n->num);
    // the maximum u64 is 18446744073709551615, 20 digits
    method_r(b, Id_append, bytes_init(buf));
    return NULL;
}

static TypeInfo info = {
    .name = "Num",
    .method_count = 4,
    .methods = {
        { .name = Id_sub, .m = num_sub },
        { .name = Id_mul, .m = num_mul },
        { .name = Id_gt, .m = num_gt },
        { .name = Id_fmt, .m = num_fmt },
    },
};
