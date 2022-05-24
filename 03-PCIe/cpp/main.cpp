#include <stdio.h>
#include <unistd.h>
#include <time.h>

#include "bdbmpcie.h"
#include "dmasplitter.h"

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

int main(int argc, char** argv) {
    init();

    BdbmPcie* pcie = BdbmPcie::getInstance();

    printf( "Starting Data Sending \n" );
    /* Send Data To Host */
    for (int i = 0; i < SIZE * SIZE; ++i) {
        pcie->userWriteWord(0, mat_a[i]);
        pcie->userWriteWord(4, mat_b[i]);
    }
    printf( "Data Sending is Done \n" );

    /* Receive Data From FPGA */
    printf( "Starting Result Receiving \n" );
    for (int i = 0; i < SIZE * SIZE; ++i) {
        if (i % SIZE == 0)
            printf("\n");

        uint32_t data = pcie->userReadWord(0);
        printf("%d ", data);
    }
    printf( "\nData Receiving is Done \n" );
    return 0;
}
