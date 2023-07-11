#include "runtime.h"

#include <stdio.h>
#include <stdlib.h>

// Reference-counted u64.

typedef struct Num {
    Value header;
    u64 num;
} Num;

Value *num_init(u64 num)
{
    Num *new = malloc(sizeof(Num));
    new->header.refcount = 1;
    new->header.tag = 0;
    new->num = num;
    return (Value *) new;
}

Value *num_sub(Value *lhs_v, Value *rhs_v)
{
    Num *lhs = (Num *) lhs_v;
    Num *rhs = (Num *) rhs_v;
    u64 res = lhs->num - rhs->num;
    decref(lhs_v);
    decref(rhs_v);
    return num_init(res);
}

Value *num_mul(Value *lhs_v, Value *rhs_v)
{
    Num *lhs = (Num *) lhs_v;
    Num *rhs = (Num *) rhs_v;
    u64 res = lhs->num * rhs->num;
    decref(lhs_v);
    decref(rhs_v);
    return num_init(res);
}

Value *num_gt(Value *lhs_v, Value *rhs_v)
{
    Num *lhs = (Num *) lhs_v;
    Num *rhs = (Num *) rhs_v;
    bool res = lhs->num > rhs->num;
    decref(lhs_v);
    decref(rhs_v);
    return bool_init(res);
}

void num_fmt(Value *n_v, Value **b)
{
    Num *n = (Num *) n_v;
    char buf[21] = {0}; // fully zeroed
    sprintf(buf, "%"PRIu64, n->num);
    // the maximum u64 is 18446744073709551615, 20 digits
    bytes_append(b, bytes_init(buf));
    decref(n_v);
}
