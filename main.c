#include "include/raylib.h"
#include "include/raymath.h"
#include <stdio.h>

int main(void) {
    Vector2 a = {.x=1.0, .y=2.0};

    Vector2 b = {.x=5.0, .y=7.0};
    Vector2 c = Vector2Add(a, b);
    printf("c: %f %f\n", c.x, c.y);
    return 0;
}
