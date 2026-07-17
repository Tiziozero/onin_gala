#include <stddef.h>
typedef struct Apple Apple;
struct Fruit {
    float x;
    float y;
    struct { size_t a; } a;
};
struct Apple {
    size_t s;
};

int main(void) {
}
