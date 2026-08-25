#include "include/raylib.h"
#include "include/raymath.h"
#include <stddef.h>
#include <stdio.h>

typedef struct {
    Vector2 a;
    Vector2 b;
    Texture t;
    Rectangle r;
    char* s;
    char c;
    size_t i;
} Something;
typedef struct {
    int a;
    float b;
    char c;
    size_t s;
    void* ptr;
    int d;
    double e;
} non_agregate_thing;
typedef struct {
    int a, b, c;
    long long d;
} SmallAgg;
void f(SmallAgg a);
int main(void) {
    SmallAgg sa;
    f(sa);
    Vector2 a = {.x=1.0, .y=2.0};

    Vector2 b = {.x=5.0, .y=7.0};
    Vector2 c = Vector2Add(a, b);
    printf("c: %f %f\n", c.x, c.y);
    Something s;
    non_agregate_thing n;
    return n.a;
}
