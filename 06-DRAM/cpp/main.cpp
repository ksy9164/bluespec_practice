#include <stdio.h>
#include <unistd.h>
#include <time.h>

#include "bdbmpcie.h"

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
    uint32_t* dmabuf = (uint32_t*)pcie->dmaBuffer();

    printf( "Starting Data Sending using DMA \n" );
    /* Send Data To Host */
    printf( "Sending Matrix A \n" );
    int idx = 0;
    while (idx < SIZE * SIZE) {
        for (int i = 0; i < 2 * 1024; ++i) { // 2K * 4Bytes data = 8KB
            dmabuf[i] = (uint32_t)mat_a[idx++];

            if (idx == SIZE * SIZE)
                break;
        }
        
        if (idx == SIZE * SIZE && ((SIZE * SIZE) % (512 * 4) != 0)) {
            int left_data = idx % (512 * 4); // % 8KB
            if (left_data % 4 == 0)
                pcie->userWriteWord(0, left_data / 4); 
            else
                pcie->userWriteWord(0, left_data / 4 + 1); 
        } else
            pcie->userWriteWord(0, 512); // 512 x 16bytes

        uint32_t target = pcie->userReadWord(0); // to get readDone signal
    }
        fflush(stdout);
    printf( "Sending Matrix A is Done \n" );
    fflush(stdout);

    pcie->userWriteWord(4, 0); // Signal to Change MatrixA to MatrixB

    printf( "Sending Matrix B \n" );

    idx = 0;
    while (idx < SIZE * SIZE) {
        for (int i = 0; i < 2 * 1024; ++i) { // 2K * 4Bytes data = 8KB
            dmabuf[i] = (uint32_t)mat_b[idx++];

            if (idx == SIZE * SIZE)
                break;
        }
        if (idx == SIZE * SIZE && ((SIZE * SIZE) % (512 * 4) != 0)) {
            int left_data = idx % (512 * 4); // % 8KB
            if (left_data % 4 == 0)
                pcie->userWriteWord(0, left_data / 4); 
            else
                pcie->userWriteWord(0, left_data / 4 + 1); 
        } else
            pcie->userWriteWord(0, 512); // 512 x 16bytes

        uint32_t target = pcie->userReadWord(0); // to get writeDone signal
    }
    printf( "Sending Matrix B is Done \n" );

    int output_cnt = 0;
    while (output_cnt < SIZE * SIZE) {
        pcie->userWriteWord(8, 512); // 512 x 16bytes Write request to FPGA
        uint32_t target = pcie->userReadWord(4); // to get writeDone signal
        output_cnt += 512 * 4;
        for (uint32_t i = 0; i < 4 * 512; i++) {
            if (i % 64 == 0)
                printf("\n");

            printf("%d ",dmabuf[i]);
        }
    }
    printf( "\nData Receiving is Done \n" );
    return 0;
}
