#ifndef TESTLIB_H
#define TESTLIB_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// ───────────── basic arithmetic ─────────────

int tl_add(int a, int b);
int tl_sub(int a, int b);
int tl_mul(int a, int b);
int tl_div(int a, int b);
int tl_mod(int a, int b);

long tl_factorial(int n);
int tl_is_prime(int n);

// ───────────── floating point ─────────────

double tl_add_double(double a, double b);
double tl_mul_double(double a, double b);
float tl_add_float(float a, float b);

double tl_avg(const double *values, size_t count);
double tl_dot(const double *a, const double *b, size_t count);

// ───────────── pointers / memory ─────────────

void tl_fill_ints(int *values, size_t count, int value);
void tl_increment_ints(int *values, size_t count);
int tl_sum_ints(const int *values, size_t count);

void *tl_mem_alloc(size_t size);
void tl_mem_free(void *ptr);

void tl_mem_set(void *ptr, int value, size_t size);
void tl_mem_copy(void *dest, const void *src, size_t size);

// ───────────── strings ─────────────

size_t tl_str_len(const char *s);
void tl_str_reverse(char *s);
int tl_str_is_palindrome(const char *s);
int tl_str_equal(const char *a, const char *b);
const char *tl_version(void);

// ───────────── global state ─────────────

void tl_counter_reset(void);
int tl_counter_next(void);
int tl_counter_get(void);

// ───────────── structs ─────────────

typedef struct {
    int x;
    int y;
} tl_point;

typedef struct {
    int sum;
    int count;
    double mean;
} tl_stats;

typedef struct {
    int32_t id;
    int32_t flags;
    double value;
    void *ptr;
} tl_record;

tl_point tl_point_make(int x, int y);
tl_point tl_point_add(tl_point a, tl_point b);
int tl_point_distance_squared(tl_point p);

tl_stats tl_stats_compute(const int *values, size_t count);
tl_record tl_record_make(int32_t id, int32_t flags, double value, void *ptr);

// ───────────── callbacks / function pointers ─────────────

typedef int (*tl_int_transform)(int value);
typedef double (*tl_double_transform)(double value);

int tl_call_int(tl_int_transform fn, int value);
double tl_call_double(tl_double_transform fn, double value);

void tl_map_ints(
    int *values,
    size_t count,
    tl_int_transform fn
);

double tl_reduce_double(
    const double *values,
    size_t count,
    tl_double_transform fn
);

// ───────────── variadics ─────────────

int tl_sum_variadic(int count, ...);
double tl_sum_variadic_double(int count, ...);

void tl_printf(const char *fmt, ...);

// ───────────── libc / OS ─────────────

int tl_getpid(void);
int tl_getppid(void);

long tl_sys_getpid(void);
long tl_sys_write(int fd, const void *buf, size_t count);

int tl_errno_test(void);

// ───────────── Linux syscalls ─────────────

long tl_syscall0(long number);
long tl_syscall1(long number, long a1);
long tl_syscall2(long number, long a1, long a2);
long tl_syscall3(long number, long a1, long a2, long a3);

// ───────────── time ─────────────

uint64_t tl_unix_time(void);

// ───────────── bit operations ─────────────

uint32_t tl_popcount32(uint32_t x);
uint64_t tl_popcount64(uint64_t x);

uint32_t tl_rotate_left32(uint32_t x, int n);
uint64_t tl_rotate_left64(uint64_t x, int n);

// ───────────── signed/unsigned edge cases ─────────────

uint32_t tl_u32_max(void);
uint64_t tl_u64_max(void);

int64_t tl_i64_min(void);
int64_t tl_i64_max(void);

// ───────────── byte operations ─────────────

uint8_t tl_byte_xor(uint8_t a, uint8_t b);
int8_t tl_byte_signed(int8_t x);

#ifdef __cplusplus
}
#endif

#endif
