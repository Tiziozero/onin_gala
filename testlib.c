// build: gcc -shared -fPIC -o libfntest.so testlib.c

int call_i32(int (*f)(int, int), int x, int y) {
    return f(x, y);
}

double call_f64(double (*f)(double), double x) {
    return f(x);
}

static int seven_c(void) {
    return 7;
}

// takes a fn that itself takes a fn
int call_nested(int (*f)(int (*)(void))) {
    return f(seven_c);
}

static int add_c(int a, int b) {
    return a + b;
}

// returns a fn pointer
int (*get_adder(void))(int, int) {
    return add_c;
}
