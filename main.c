#include <inttypes.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
    printf("Hello, world!\n");

    uint64_t i, n;
    for (n = 1, i = 10; i > 0; i--)
        n *= i;
    printf("10! = %"PRIu64"\n", n);

    return 0;
}
