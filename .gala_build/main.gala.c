void printf(char* fmt, ...);
void* calloc(long int n,long int size);
void memcpy(void* dest,void* src,long int size);
void free(void* ptr);
void InitWindow(long int width,long int height,char* title);
void CloseWindow();
char WindowShouldClose();
void BeginDrawing();
void EndDrawing();
void ClearBackground(struct {char r; char g; char b; char a; } color);
struct {char r; char g; char b; char a; } GetColor(int v);
char* main_fn_to_cstr(struct { void* ptr; long int length; } s);
void main_fn_print_int(struct { void* ptr; long int length; } s,long int n);
void main_fn_print_flt(struct { void* ptr; long int length; } s,float n);
struct {float x; float y; } Vector2Add(struct {float x; float y; } a,struct {float x; float y; } b);
long int main_fn_main();
char* main_fn_to_cstr(struct { void* ptr; long int length; } s) {
}
void main_fn_print_int(struct { void* ptr; long int length; } s,long int n) {
}
void main_fn_print_flt(struct { void* ptr; long int length; } s,float n) {
}
long int main_fn_main() {
}
