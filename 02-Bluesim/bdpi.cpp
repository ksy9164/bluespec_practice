#include <stdio.h>
#include <stdint.h>

#define F_NAME_A "../data/matrix_a.txt"
#define F_NAME_B "../data/matrix_b.txt"

#define SIZE 64

int mat_a[SIZE*SIZE];
int mat_b[SIZE*SIZE];

void init() {
    FILE* file_a = fopen (F_NAME_A, "r");
    FILE* file_b = fopen (F_NAME_B, "r");
    for (int i = 0; i < SIZE * SIZE; ++i) {
        fscanf(file_a, "%d", &mat_a[i]);    
        fscanf(file_b, "%d", &mat_b[i]);    
    }
    fclose (file_a);
    fclose (file_b);
}

extern "C" int bdpi_read_mat_a(uint32_t offset) {
    init();
    int idx = offset;
    return mat_a[offset];
}

extern "C" int bdpi_read_mat_b(uint32_t offset) {
    init();
    int idx = offset;
    return mat_b[offset];
}

extern "C" void bdpi_put_result(uint32_t result) {
    printf( "%d ", (int)result);
}
