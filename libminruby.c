#include <stdio.h>

long minruby_p(long x) {
    printf("%ld\n", x);
    return x;
}

long minruby_putc(long x) {
    putchar(x);
    return x;
}

long minruby_add(long x, long y) {
    return x + y;
}
