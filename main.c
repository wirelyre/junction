#include "runtime.h"

int main(int argc, char *argv[])
{
    // object model: values are pointers to heap allocations
    // they are immutable (conceptually)
    // they have reference counts to keep track of when to free them
    Value *b1 = bytes_init("Hello, wo"); // b1: Bytes
    Value *b2 = bytes_init("rld!\n");    // b2: Bytes

    // a `Bytes *` takes ownership; increment the refcount to keep your own copy
    // a `Bytes **` doesn't; it's like a mutable pointer to immutable data
    bytes_append(&b1, b2); // gives away `b2`
    bytes_print(b1);       // gives away `b1`
    // now `b1` and `b2` must not be used (in fact, they have been freed)

    b1 = bytes_init("hello ");
    b2 = incref(b1);
    // `b1` and `b2` are basically different objects now
    // they will only be modified as an optimization if the refcount is 1

    bytes_append(&b1, incref(b2)); // `b1` and `b2` are kept
    bytes_append(&b1, incref(b2)); // still kept
    bytes_append(&b1, b2); // `b2` is gone

    bytes_print(incref(b1)); // `b1` is kept
    bytes_print(b1); // `b1` is gone

    bytes_print(bytes_init("\n")); // value is allocated and freed (no leak)



    // calculate 10 factorial

    Value *n = num_init(1);  // n: Num
    Value *i = num_init(10); // i: Num
    while (bool_get(num_gt(incref(i), num_init(0)))) {
        n = num_mul(n, incref(i));
        i = num_sub(i, num_init(1));
    }
    decref(i);

    Value *b = bytes_init("10! = "); // b: Bytes
    num_fmt(n, &b);
    bytes_append(&b, bytes_init("\n"));
    bytes_print(b);

    return 0;
}
