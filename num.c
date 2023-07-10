#include "runtime.h"

#include <stdio.h>
#include <stdlib.h>

// Reference-counted u64.

struct Num {
    u32 refcount;
    u64 num;
};

Num *num_init(u64 num)
{
    Num *new = malloc(sizeof(Num));
    new->refcount = 1;
    new->num = num;
    return new;
}

Num *num_incref(Num *n)
{
    n->refcount++;
    return n;
}

void num_decref(Num *n)
{
    n->refcount--;
    if (n->refcount == 0)
        free(n);
}



Num *num_sub(Num *lhs, Num *rhs)
{
    u64 res = lhs->num - rhs->num;
    num_decref(lhs);
    num_decref(rhs);
    return num_init(res);
}

Num *num_mul(Num *lhs, Num *rhs)
{
    u64 res = lhs->num * rhs->num;
    num_decref(lhs);
    num_decref(rhs);
    return num_init(res);
}

Bool *num_gt(Num *lhs, Num *rhs)
{
    bool res = lhs->num > rhs->num;
    num_decref(lhs);
    num_decref(rhs);
    return bool_init(res);
}

void num_fmt(Num *n, Bytes **b)
{
    char buf[21] = {0}; // fully zeroed
    sprintf(buf, "%"PRIu64, n->num);
    // the maximum u64 is 18446744073709551615, 20 digits
    bytes_append(b, bytes_init(buf));
    num_decref(n);
}
