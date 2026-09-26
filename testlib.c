#include "testlib.h"

#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <time.h>

// ───────────── basic arithmetic ─────────────

int tl_add(int a, int b) {
    return a + b;
}

int tl_sub(int a, int b) {
    return a - b;
}

int tl_mul(int a, int b) {
    return a * b;
}

int tl_div(int a, int b) {
    if (b == 0)
        return 0;

    return a / b;
}

int tl_mod(int a, int b) {
    if (b == 0)
        return 0;

    return a % b;
}

long tl_factorial(int n) {
    if (n < 0)
        return -1;

    long result = 1;

    for (int i = 2; i <= n; i++)
        result *= i;

    return result;
}

int tl_is_prime(int n) {
    if (n < 2)
        return 0;

    for (int i = 2; (long)i * i <= n; i++) {
        if (n % i == 0)
            return 0;
    }

    return 1;
}

// ───────────── floating point ─────────────

double tl_add_double(double a, double b) {
    return a + b;
}

double tl_mul_double(double a, double b) {
    return a * b;
}

float tl_add_float(float a, float b) {
    return a + b;
}

double tl_avg(const double *values, size_t count) {
    if (!values || count == 0)
        return 0.0;

    double sum = 0.0;

    for (size_t i = 0; i < count; i++)
        sum += values[i];

    return sum / (double)count;
}

double tl_dot(const double *a, const double *b, size_t count) {
    if (!a || !b)
        return 0.0;

    double result = 0.0;

    for (size_t i = 0; i < count; i++)
        result += a[i] * b[i];

    return result;
}

// ───────────── pointers / memory ─────────────

void tl_fill_ints(int *values, size_t count, int value) {
    if (!values)
        return;

    for (size_t i = 0; i < count; i++)
        values[i] = value;
}

void tl_increment_ints(int *values, size_t count) {
    if (!values)
        return;

    for (size_t i = 0; i < count; i++)
        values[i]++;
}

int tl_sum_ints(const int *values, size_t count) {
    if (!values)
        return 0;

    int sum = 0;

    for (size_t i = 0; i < count; i++)
        sum += values[i];

    return sum;
}

void *tl_mem_alloc(size_t size) {
    return malloc(size);
}

void tl_mem_free(void *ptr) {
    free(ptr);
}

void tl_mem_set(void *ptr, int value, size_t size) {
    memset(ptr, value, size);
}

void tl_mem_copy(void *dest, const void *src, size_t size) {
    memcpy(dest, src, size);
}

// ───────────── strings ─────────────

size_t tl_str_len(const char *s) {
    if (!s)
        return 0;

    return strlen(s);
}

void tl_str_reverse(char *s) {
    if (!s)
        return;

    size_t len = strlen(s);

    for (size_t i = 0; i < len / 2; i++) {
        char tmp = s[i];

        s[i] = s[len - 1 - i];
        s[len - 1 - i] = tmp;
    }
}

int tl_str_is_palindrome(const char *s) {
    if (!s)
        return 0;

    size_t len = strlen(s);

    for (size_t i = 0; i < len / 2; i++) {
        if (s[i] != s[len - 1 - i])
            return 0;
    }

    return 1;
}

int tl_str_equal(const char *a, const char *b) {
    if (!a || !b)
        return a == b;

    return strcmp(a, b) == 0;
}

const char *tl_version(void) {
    return "testlib 2.0.0";
}

// ───────────── global state ─────────────

static int g_counter = 0;

void tl_counter_reset(void) {
    g_counter = 0;
}

int tl_counter_next(void) {
    return g_counter++;
}

int tl_counter_get(void) {
    return g_counter;
}

// ───────────── structs ─────────────

tl_point tl_point_make(int x, int y) {
    tl_point result = {
        .x = x,
        .y = y
    };

    return result;
}

tl_point tl_point_add(tl_point a, tl_point b) {
    tl_point result = {
        .x = a.x + b.x,
        .y = a.y + b.y
    };

    return result;
}

int tl_point_distance_squared(tl_point p) {
    return p.x * p.x + p.y * p.y;
}

tl_stats tl_stats_compute(const int *values, size_t count) {
    tl_stats result = {
        .sum = 0,
        .count = 0,
        .mean = 0.0
    };

    if (!values || count == 0)
        return result;

    for (size_t i = 0; i < count; i++)
        result.sum += values[i];

    result.count = (int)count;
    result.mean = (double)result.sum / (double)count;

    return result;
}

tl_record tl_record_make(
    int32_t id,
    int32_t flags,
    double value,
    void *ptr
) {
    tl_record result = {
        .id = id,
        .flags = flags,
        .value = value,
        .ptr = ptr
    };

    return result;
}

// ───────────── callbacks ─────────────

int tl_call_int(tl_int_transform fn, int value) {
    if (!fn)
        return 0;

    return fn(value);
}

double tl_call_double(tl_double_transform fn, double value) {
    if (!fn)
        return 0.0;

    return fn(value);
}

void tl_map_ints(
    int *values,
    size_t count,
    tl_int_transform fn
) {
    if (!values || !fn)
        return;

    for (size_t i = 0; i < count; i++)
        values[i] = fn(values[i]);
}

double tl_reduce_double(
    const double *values,
    size_t count,
    tl_double_transform fn
) {
    if (!values || !fn)
        return 0.0;

    double result = 0.0;

    for (size_t i = 0; i < count; i++)
        result += fn(values[i]);

    return result;
}

// ───────────── variadics ─────────────

int tl_sum_variadic(int count, ...) {
    va_list args;
    va_start(args, count);

    int result = 0;

    for (int i = 0; i < count; i++)
        result += va_arg(args, int);

    va_end(args);

    return result;
}

double tl_sum_variadic_double(int count, ...) {
    va_list args;
    va_start(args, count);

    double result = 0.0;

    for (int i = 0; i < count; i++)
        result += va_arg(args, double);

    va_end(args);

    return result;
}

void tl_printf(const char *fmt, ...) {
    va_list args;

    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
}

// ───────────── libc / OS ─────────────

int tl_getpid(void) {
    return (int)getpid();
}

int tl_getppid(void) {
    return (int)getppid();
}

long tl_sys_getpid(void) {
    return syscall(SYS_getpid);
}

long tl_sys_write(int fd, const void *buf, size_t count) {
    return syscall(SYS_write, fd, buf, count);
}

int tl_errno_test(void) {
    errno = ENOENT;
    return errno;
}

// ───────────── Linux syscalls ─────────────

long tl_syscall0(long number) {
    return syscall(number);
}

long tl_syscall1(long number, long a1) {
    return syscall(number, a1);
}

long tl_syscall2(long number, long a1, long a2) {
    return syscall(number, a1, a2);
}

long tl_syscall3(long number, long a1, long a2, long a3) {
    return syscall(number, a1, a2, a3);
}

// ───────────── time ─────────────

uint64_t tl_unix_time(void) {
    return (uint64_t)time(NULL);
}

// ───────────── bit operations ─────────────

uint32_t tl_popcount32(uint32_t x) {
    return (uint32_t)__builtin_popcount(x);
}

uint64_t tl_popcount64(uint64_t x) {
    return (uint64_t)__builtin_popcountll(x);
}

uint32_t tl_rotate_left32(uint32_t x, int n) {
    n &= 31;

    if (n == 0)
        return x;

    return (x << n) | (x >> (32 - n));
}

uint64_t tl_rotate_left64(uint64_t x, int n) {
    n &= 63;

    if (n == 0)
        return x;

    return (x << n) | (x >> (64 - n));
}

// ───────────── signed/unsigned ─────────────

uint32_t tl_u32_max(void) {
    return UINT32_MAX;
}

uint64_t tl_u64_max(void) {
    return UINT64_MAX;
}

int64_t tl_i64_min(void) {
    return INT64_MIN;
}

int64_t tl_i64_max(void) {
    return INT64_MAX;
}

// ───────────── bytes ─────────────

uint8_t tl_byte_xor(uint8_t a, uint8_t b) {
    return a ^ b;
}

int8_t tl_byte_signed(int8_t x) {
    return x;
}
