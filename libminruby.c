#include <stdio.h>

int print_int(int x) {
    printf("%d\n", x);
    return x;
}

int p(int x) {
    return print_int(x);
}

int add(int x, int y) {
    return x + y;
}
