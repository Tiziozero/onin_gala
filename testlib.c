#include <stdio.h>
#include <stdint.h>

// Simple structs intended to match the Gala declarations exactly.
typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
} Color;

typedef struct {
    float x;
    float y;
} V2;

typedef struct {
    int32_t a;
    int32_t b;
} Pair;

typedef struct {
    float x;
    float y;
    float z;
} V3;

void test_i32(int32_t n) {
    printf("test_i32: %d\\n", n);
}

void test_i64(int64_t n) {
    printf("test_i64: %lld\\n", (long long)n);
}

void test_f32(float n) {
    printf("test_f32: %f\\n", (double)n);
}

void test_byte(uint8_t n) {
    printf("test_byte: %u (0x%02x)\\n", (unsigned)n, (unsigned)n);
}

void test_i32_pair(int32_t a, int32_t b) {
    printf("test_i32_pair: a=%d b=%d\\n", a, b);
}

void test_mixed(int32_t i, int64_t l, float f, uint8_t b) {
    printf("test_mixed: i=%d l=%lld f=%f b=%u\\n",
           i, (long long)l, (double)f, (unsigned)b);
}

void test_color(Color c) {
    printf("test_color: r=%u g=%u b=%u a=%u\\n",
           (unsigned)c.r,
           (unsigned)c.g,
           (unsigned)c.b,
           (unsigned)c.a);
}

void test_v2(V2 v) {
    printf("test_v2: x=%f y=%f\\n", (double)v.x, (double)v.y);
}

void test_pair(Pair p) {
    printf("test_pair: a=%d b=%d\\n", p.a, p.b);
}

void test_v3(V3 v) {
    printf("test_v3: x=%f y=%f z=%f\\n",
           (double)v.x, (double)v.y, (double)v.z);
}

void test_mixed_structs(Color c, V2 v, int64_t n) {
    printf("test_mixed_structs: color=(%u,%u,%u,%u) v=(%f,%f) n=%lld\\n",
           (unsigned)c.r,
           (unsigned)c.g,
           (unsigned)c.b,
           (unsigned)c.a,
           (double)v.x,
           (double)v.y,
           (long long)n);
}

void test_color_ptr(const Color *c) {
    if (c == NULL) {
        printf("test_color_ptr: NULL\\n");
        return;
    }

    printf("test_color_ptr: r=%u g=%u b=%u a=%u\\n",
           (unsigned)c->r,
           (unsigned)c->g,
           (unsigned)c->b,
           (unsigned)c->a);
}

Color make_color(uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    Color c = { r, g, b, a };
    printf("make_color: returning (%u,%u,%u,%u)\\n",
           (unsigned)r, (unsigned)g, (unsigned)b, (unsigned)a);
    return c;
}

V2 make_v2(float x, float y) {
    V2 v = { x, y };
    printf("make_v2: returning (%f,%f)\\n", (double)x, (double)y);
    return v;
}

Pair make_pair(int32_t a, int32_t b) {
    Pair p = { a, b };
    printf("make_pair: returning (%d,%d)\\n", a, b);
    return p;
}

V3 make_v3(float x, float y, float z) {
    V3 v = { x, y, z };
    printf("make_v3: returning (%f,%f,%f)\\n",
           (double)x, (double)y, (double)z);
    return v;
}

int32_t inspect_color(Color c) {
    int32_t packed = ((int32_t)c.r << 24) |
                     ((int32_t)c.g << 16) |
                     ((int32_t)c.b << 8) |
                     (int32_t)c.a;
    printf("inspect_color: packed=0x%08x\\n", (unsigned)packed);
    return packed;
}

void print_struct_layouts(void) {
    printf("sizeof(Color)=%zu alignof(Color)=%zu\\n", sizeof(Color), _Alignof(Color));
    printf("sizeof(V2)=%zu alignof(V2)=%zu\\n", sizeof(V2), _Alignof(V2));
    printf("sizeof(Pair)=%zu alignof(Pair)=%zu\\n", sizeof(Pair), _Alignof(Pair));
    printf("sizeof(V3)=%zu alignof(V3)=%zu\\n", sizeof(V3), _Alignof(V3));
}
