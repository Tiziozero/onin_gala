// abi_struct_calls.c
//
// Compile examples:
//
//   clang -O0 -S abi_struct_calls.c -o abi.s
//   clang -O2 -S abi_struct_calls.c -o abi.s
//
// LLVM IR:
//   clang -O0 -emit-llvm -S abi_struct_calls.c -o abi.ll
//
// Useful:
//   clang -O0 -S -fverbose-asm abi_struct_calls.c -o abi.s
//
// System V AMD64 ABI struct / function-call torture test.
//

#include <stdint.h>
#include <stdarg.h>

// Prevent the optimizer from simply deleting things.
volatile uint64_t sink;


// ------------------------------------------------------------
// Basic scalar functions
// ------------------------------------------------------------

__attribute__((noinline))
int f_int(int a)
{
    sink += a;
    return a + 1;
}

__attribute__((noinline))
long f_long(long a, long b)
{
    sink += a + b;
    return a * b;
}

__attribute__((noinline))
double f_double(double a, double b)
{
    return a + b;
}

__attribute__((noinline))
float f_float(float a, float b)
{
    return a * b;
}


// ------------------------------------------------------------
// Very small integer structs
// ------------------------------------------------------------

struct S1
{
    uint8_t a;
};

struct S2
{
    uint16_t a;
};

struct S3
{
    uint8_t a;
    uint16_t b;
};

struct S4
{
    uint32_t a;
};

struct S5
{
    uint32_t a;
    uint32_t b;
};

struct S8
{
    uint64_t a;
};

struct S12
{
    uint64_t a;
    uint32_t b;
};

struct S16
{
    uint64_t a;
    uint64_t b;
};


// ------------------------------------------------------------
// Integer structs crossing eightbyte boundaries
// ------------------------------------------------------------

struct Int3
{
    uint64_t a;
    uint64_t b;
    uint64_t c;
};

struct Int4
{
    uint64_t a;
    uint64_t b;
    uint64_t c;
    uint64_t d;
};


// ------------------------------------------------------------
// Pure SSE structs
// ------------------------------------------------------------

struct F1
{
    float a;
};

struct F2
{
    float a;
    float b;
};

struct F3
{
    float a;
    float b;
    float c;
};

struct F4
{
    float a;
    float b;
    float c;
    float d;
};

struct D1
{
    double a;
};

struct D2
{
    double a;
    double b;
};

struct D3
{
    double a;
    double b;
    double c;
};


// ------------------------------------------------------------
// Mixed INTEGER / SSE structs
// ------------------------------------------------------------

struct IntFloat
{
    int a;
    float b;
};

struct FloatInt
{
    float a;
    int b;
};

struct IntDouble
{
    int a;
    double b;
};

struct DoubleInt
{
    double a;
    int b;
};

struct LongFloat
{
    long a;
    float b;
};

struct FloatLong
{
    float a;
    long b;
};

struct LongDouble_
{
    long a;
    double b;
};

struct DoubleLong
{
    double a;
    long b;
};


// ------------------------------------------------------------
// Nested structs
// ------------------------------------------------------------

struct NestedInt
{
    struct S8 a;
    struct S8 b;
};

struct NestedFloat
{
    struct F2 a;
    struct F2 b;
};

struct NestedMixed
{
    struct IntFloat a;
    struct IntFloat b;
};

struct NestedLarge
{
    struct S16 a;
    struct S16 b;
};


// ------------------------------------------------------------
// Arrays inside structs
// ------------------------------------------------------------

struct ArrayInt2
{
    int a[2];
};

struct ArrayInt3
{
    int a[3];
};

struct ArrayDouble2
{
    double a[2];
};

struct ArrayFloat4
{
    float a[4];
};


// ------------------------------------------------------------
// Packed / weird layout
// ------------------------------------------------------------

struct Packed1
{
    uint8_t a;
    uint64_t b;
} __attribute__((packed));

struct Packed2
{
    uint8_t a;
    uint32_t b;
} __attribute__((packed));

struct Packed3
{
    uint8_t a;
    double b;
} __attribute__((packed));


// ------------------------------------------------------------
// Unions
// ------------------------------------------------------------

union U64
{
    uint64_t i;
    double d;
};

union U128
{
    struct S16 s;
    struct D2 d;
};

union MixedUnion
{
    struct IntFloat a;
    struct D1 b;
};


// ------------------------------------------------------------
// Return structs
// ------------------------------------------------------------

__attribute__((noinline))
struct S1 ret_s1(uint8_t x)
{
    return (struct S1){ x };
}

__attribute__((noinline))
struct S5 ret_s5(uint32_t a, uint32_t b)
{
    return (struct S5){ a, b };
}

__attribute__((noinline))
struct S8 ret_s8(uint64_t x)
{
    return (struct S8){ x };
}

__attribute__((noinline))
struct S12 ret_s12(uint64_t a, uint32_t b)
{
    return (struct S12){ a, b };
}

__attribute__((noinline))
struct S16 ret_s16(uint64_t a, uint64_t b)
{
    return (struct S16){ a, b };
}

__attribute__((noinline))
struct Int3 ret_int3(uint64_t a, uint64_t b, uint64_t c)
{
    return (struct Int3){ a, b, c };
}

__attribute__((noinline))
struct F1 ret_f1(float a)
{
    return (struct F1){ a };
}

__attribute__((noinline))
struct F2 ret_f2(float a, float b)
{
    return (struct F2){ a, b };
}

__attribute__((noinline))
struct F4 ret_f4(float a, float b, float c, float d)
{
    return (struct F4){ a, b, c, d };
}

__attribute__((noinline))
struct D1 ret_d1(double a)
{
    return (struct D1){ a };
}

__attribute__((noinline))
struct D2 ret_d2(double a, double b)
{
    return (struct D2){ a, b };
}

__attribute__((noinline))
struct IntFloat ret_int_float(int a, float b)
{
    return (struct IntFloat){ a, b };
}

__attribute__((noinline))
struct FloatInt ret_float_int(float a, int b)
{
    return (struct FloatInt){ a, b };
}

__attribute__((noinline))
struct IntDouble ret_int_double(int a, double b)
{
    return (struct IntDouble){ a, b };
}

__attribute__((noinline))
struct DoubleInt ret_double_int(double a, int b)
{
    return (struct DoubleInt){ a, b };
}

__attribute__((noinline))
struct LongFloat ret_long_float(long a, float b)
{
    return (struct LongFloat){ a, b };
}

__attribute__((noinline))
struct FloatLong ret_float_long(float a, long b)
{
    return (struct FloatLong){ a, b };
}


// ------------------------------------------------------------
// Struct arguments
// ------------------------------------------------------------

__attribute__((noinline))
void arg_s1(struct S1 x)
{
    sink += x.a;
}

__attribute__((noinline))
void arg_s5(struct S5 x)
{
    sink += x.a + x.b;
}

__attribute__((noinline))
void arg_s8(struct S8 x)
{
    sink += x.a;
}

__attribute__((noinline))
void arg_s12(struct S12 x)
{
    sink += x.a + x.b;
}

__attribute__((noinline))
void arg_s16(struct S16 x)
{
    sink += x.a + x.b;
}

__attribute__((noinline))
void arg_int3(struct Int3 x)
{
    sink += x.a + x.b + x.c;
}

__attribute__((noinline))
void arg_f1(struct F1 x)
{
    sink += (uint64_t)x.a;
}

__attribute__((noinline))
void arg_f2(struct F2 x)
{
    sink += (uint64_t)(x.a + x.b);
}

__attribute__((noinline))
void arg_f4(struct F4 x)
{
    sink += (uint64_t)(x.a + x.b + x.c + x.d);
}

__attribute__((noinline))
void arg_d1(struct D1 x)
{
    sink += (uint64_t)x.a;
}

__attribute__((noinline))
void arg_d2(struct D2 x)
{
    sink += (uint64_t)(x.a + x.b);
}

__attribute__((noinline))
void arg_int_float(struct IntFloat x)
{
    sink += x.a + (int)x.b;
}

__attribute__((noinline))
void arg_float_int(struct FloatInt x)
{
    sink += (int)x.a + x.b;
}

__attribute__((noinline))
void arg_int_double(struct IntDouble x)
{
    sink += x.a + (int)x.b;
}

__attribute__((noinline))
void arg_double_int(struct DoubleInt x)
{
    sink += (int)x.a + x.b;
}

__attribute__((noinline))
void arg_long_float(struct LongFloat x)
{
    sink += x.a + (long)x.b;
}

__attribute__((noinline))
void arg_float_long(struct FloatLong x)
{
    sink += (long)x.a + x.b;
}


// ------------------------------------------------------------
// Multiple structs in one call
// ------------------------------------------------------------

__attribute__((noinline))
void many_integer_structs(
    struct S8 a,
    struct S8 b,
    struct S8 c,
    struct S8 d,
    struct S8 e,
    struct S8 f,
    struct S8 g
)
{
    sink +=
        a.a + b.a + c.a + d.a +
        e.a + f.a + g.a;
}

__attribute__((noinline))
void many_sse_structs(
    struct D1 a,
    struct D1 b,
    struct D1 c,
    struct D1 d,
    struct D1 e,
    struct D1 f,
    struct D1 g,
    struct D1 h,
    struct D1 i
)
{
    sink += (uint64_t)(
        a.a + b.a + c.a +
        d.a + e.a + f.a +
        g.a + h.a + i.a
    );
}


// ------------------------------------------------------------
// Mix scalar and struct arguments
// ------------------------------------------------------------

__attribute__((noinline))
void mixed_args1(
    int a,
    struct S16 b,
    double c,
    struct F2 d,
    long e
)
{
    sink += a + b.a + b.b + (long)c + (long)d.a + (long)d.b + e;
}

__attribute__((noinline))
void mixed_args2(
    struct IntDouble a,
    int b,
    struct DoubleInt c,
    double d,
    struct S8 e
)
{
    sink +=
        a.a +
        (long)a.b +
        b +
        (long)c.a +
        c.b +
        (long)d +
        e.a;
}


// ------------------------------------------------------------
// Large structs / indirect passing
// ------------------------------------------------------------

__attribute__((noinline))
struct Int3 large_return(struct Int3 x)
{
    x.a += 1;
    x.b += 2;
    x.c += 3;

    return x;
}

__attribute__((noinline))
struct Int4 huge_return(struct Int4 x)
{
    x.a += 1;
    x.b += 2;
    x.c += 3;
    x.d += 4;

    return x;
}


// ------------------------------------------------------------
// Union arguments / returns
// ------------------------------------------------------------

__attribute__((noinline))
union U64 ret_union_u64(uint64_t x)
{
    union U64 u;
    u.i = x;
    return u;
}

__attribute__((noinline))
union U128 ret_union_u128(double a, double b)
{
    union U128 u;
    u.d.a = a;
    u.d.b = b;
    return u;
}

__attribute__((noinline))
void arg_union_u64(union U64 x)
{
    sink += x.i;
}

__attribute__((noinline))
void arg_union_u128(union U128 x)
{
    sink += x.s.a + x.s.b;
}


// ------------------------------------------------------------
// Variadic tests
// ------------------------------------------------------------

__attribute__((noinline))
void variadic_ints(int count, ...)
{
    va_list ap;

    va_start(ap, count);

    for (int i = 0; i < count; i++)
    {
        sink += va_arg(ap, int);
    }

    va_end(ap);
}

__attribute__((noinline))
void variadic_doubles(int count, ...)
{
    va_list ap;

    va_start(ap, count);

    for (int i = 0; i < count; i++)
    {
        sink += (uint64_t)va_arg(ap, double);
    }

    va_end(ap);
}


// ------------------------------------------------------------
// Call-site torture test
// ------------------------------------------------------------

__attribute__((noinline))
void test_calls(void)
{
    struct S1 s1 = { 1 };
    struct S5 s5 = { 2, 3 };
    struct S8 s8 = { 4 };
    struct S12 s12 = { 5, 6 };
    struct S16 s16 = { 7, 8 };

    struct Int3 i3 = { 10, 11, 12 };

    struct F1 f1 = { 1.0f };
    struct F2 f2 = { 2.0f, 3.0f };
    struct F4 f4 = { 4.0f, 5.0f, 6.0f, 7.0f };

    struct D1 d1 = { 1.0 };
    struct D2 d2 = { 2.0, 3.0 };

    struct IntFloat int_float = { 1, 2.0f };
    struct FloatInt float_int = { 3.0f, 4 };

    struct IntDouble int_double = { 5, 6.0 };
    struct DoubleInt double_int = { 7.0, 8 };

    struct LongFloat long_float = { 9, 10.0f };
    struct FloatLong float_long = { 11.0f, 12 };


    // Basic struct arguments.
    arg_s1(s1);
    arg_s5(s5);
    arg_s8(s8);
    arg_s12(s12);
    arg_s16(s16);

    arg_int3(i3);

    arg_f1(f1);
    arg_f2(f2);
    arg_f4(f4);

    arg_d1(d1);
    arg_d2(d2);

    arg_int_float(int_float);
    arg_float_int(float_int);

    arg_int_double(int_double);
    arg_double_int(double_int);

    arg_long_float(long_float);
    arg_float_long(float_long);


    // Struct returns.
    s1 = ret_s1(20);
    s5 = ret_s5(21, 22);
    s8 = ret_s8(23);
    s12 = ret_s12(24, 25);
    s16 = ret_s16(26, 27);

    i3 = ret_int3(28, 29, 30);

    f1 = ret_f1(31.0f);
    f2 = ret_f2(32.0f, 33.0f);
    f4 = ret_f4(34.0f, 35.0f, 36.0f, 37.0f);

    d1 = ret_d1(38.0);
    d2 = ret_d2(39.0, 40.0);

    int_float = ret_int_float(41, 42.0f);
    float_int = ret_float_int(43.0f, 44);

    int_double = ret_int_double(45, 46.0);
    double_int = ret_double_int(47.0, 48);

    long_float = ret_long_float(49, 50.0f);
    float_long = ret_float_long(51.0f, 52);


    // Register exhaustion.
    many_integer_structs(
        (struct S8){ 1 },
        (struct S8){ 2 },
        (struct S8){ 3 },
        (struct S8){ 4 },
        (struct S8){ 5 },
        (struct S8){ 6 },
        (struct S8){ 7 }
    );

    many_sse_structs(
        (struct D1){ 1.0 },
        (struct D1){ 2.0 },
        (struct D1){ 3.0 },
        (struct D1){ 4.0 },
        (struct D1){ 5.0 },
        (struct D1){ 6.0 },
        (struct D1){ 7.0 },
        (struct D1){ 8.0 },
        (struct D1){ 9.0 }
    );


    // Mixed classes.
    mixed_args1(
        1,
        (struct S16){ 2, 3 },
        4.0,
        (struct F2){ 5.0f, 6.0f },
        7
    );

    mixed_args2(
        (struct IntDouble){ 1, 2.0 },
        3,
        (struct DoubleInt){ 4.0, 5 },
        6.0,
        (struct S8){ 7 }
    );


    // MEMORY-class / large returns.
    i3 = large_return(i3);

    struct Int4 i4 = { 1, 2, 3, 4 };
    i4 = huge_return(i4);


    // Union tests.
    union U64 u64 = ret_union_u64(123);
    arg_union_u64(u64);

    union U128 u128 = ret_union_u128(1.0, 2.0);
    arg_union_u128(u128);


    // Variadic ABI tests.
    variadic_ints(
        8,
        1, 2, 3, 4,
        5, 6, 7, 8
    );

    variadic_doubles(
        10,
        1.0, 2.0, 3.0, 4.0, 5.0,
        6.0, 7.0, 8.0, 9.0, 10.0
    );


    // Make sure results are observable.
    sink +=
        s1.a +
        s5.a +
        s5.b +
        s8.a +
        s12.a +
        s12.b +
        s16.a +
        s16.b;

    sink +=
        i3.a +
        i3.b +
        i3.c;

    sink +=
        (uint64_t)f1.a +
        (uint64_t)f2.a +
        (uint64_t)f2.b +
        (uint64_t)d1.a +
        (uint64_t)d2.a +
        (uint64_t)d2.b;

    sink += i4.a + i4.b + i4.c + i4.d;
}


int main(void)
{
    test_calls();
    return (int)sink;
}
