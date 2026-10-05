typedef struct { float x, y; } Vector2;
typedef struct { char r, g, b, a; } Color;
void DrawTriangle(Vector2 a, Vector2 b, Vector2 c, Color color);
int main(void) {
    DrawTriangle((Vector2){.x=1, .y=1}, (Vector2){.x=1, .y=1}, (Vector2){.x=1, .y=1}, (Color){});
}
