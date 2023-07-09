#include <inttypes.h>
#include <stdio.h>

#include "runtime.h"

int main(int argc, char *argv[])
{
    // object model: values are pointers to heap allocations
    // they are immutable (conceptually)
    // they have reference counts to keep track of when to free them
    Bytes *b1 = bytes_init("Hello, wo");
    Bytes *b2 = bytes_init("rld!\n");

    // a `Bytes *` takes ownership; increment the refcount to keep your own copy
    // a `Bytes **` doesn't; it's like a mutable pointer to immutable data
    bytes_append(&b1, b2); // gives away `b2`
    bytes_print(b1);       // gives away `b1`
    // now `b1` and `b2` must not be used (in fact, they have been freed)

    b1 = bytes_init("hello ");
    b2 = bytes_incref(b1);
    // `b1` and `b2` are basically different objects now
    // they will only be modified as an optimization if the refcount is 1

    bytes_append(&b1, bytes_incref(b2)); // `b1` and `b2` are kept
    bytes_append(&b1, bytes_incref(b2)); // still kept
    bytes_append(&b1, b2); // `b2` is gone

    bytes_print(bytes_incref(b1)); // `b1` is kept
    bytes_print(b1); // `b1` is gone

    bytes_print(bytes_init("\n")); // value is allocated and freed (no leak)



    uint64_t i, n;
    for (n = 1, i = 10; i > 0; i--)
        n *= i;
    printf("10! = %"PRIu64"\n", n);

    return 0;
}
