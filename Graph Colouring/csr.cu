#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#define MAX_COLORS 128

__global__ void colorGraph(int *row_ptr, int *col_ind, int *colors, int num_nodes) {
    int node = blockIdx.x * blockDim.x + threadIdx.x;
    if (node >= num_nodes) return;
    
    bool available[MAX_COLORS];
    for (int i = 0; i < MAX_COLORS; i++) available[i] = true;
    
    int row_start = row_ptr[node];
    int row_end = row_ptr[node + 1];
    for (int i = row_start; i < row_end; i++) {
        int neighbor = col_ind[i];
        if (colors[neighbor] != -1) {
            available[colors[neighbor]] = false;
        }
    }
    
    for (int c = 0; c < MAX_COLORS; c++) {
        if (available[c]) {
            colors[node] = c;
            break;
        }
    }
}


void graphColoring(int *h_row_ptr, int *h_col_ind, int *h_adj_list, int *h_offset, int *h_colors, int num_nodes) {
    int *d_row_ptr, *d_col_ind, *d_adj_list, *d_offset, *d_colors;
    cudaMalloc(&d_colors, num_nodes * sizeof(int));
    cudaMemcpy(d_colors, h_colors, num_nodes * sizeof(int), cudaMemcpyHostToDevice);
    
        cudaMalloc(&d_row_ptr, (num_nodes + 1) * sizeof(int));
        cudaMalloc(&d_col_ind, h_row_ptr[num_nodes] * sizeof(int));
        cudaMemcpy(d_row_ptr, h_row_ptr, (num_nodes + 1) * sizeof(int), cudaMemcpyHostToDevice);
        cudaMemcpy(d_col_ind, h_col_ind, h_row_ptr[num_nodes] * sizeof(int), cudaMemcpyHostToDevice);
        
        colorGraph<<<num_nodes, 256>>>(d_row_ptr, d_col_ind, d_colors, num_nodes);
        
        cudaFree(d_row_ptr);
        cudaFree(d_col_ind);

    
    cudaMemcpy(h_colors, d_colors, num_nodes * sizeof(int), cudaMemcpyDeviceToHost);
    cudaFree(d_colors);
}

int main() {
    int num_nodes = 5;
    int h_row_ptr[] = {0, 2, 5, 7, 9, 10};
    int h_col_ind[] = {1, 4, 0, 2, 4, 1, 3, 2, 4, 3};
    int h_adj_list[] = {1, 4, 0, 2, 4, 1, 3, 2, 4, 3};
    int h_offset[] = {0, 2, 5, 7, 9, 10};
    int h_colors[5];
    
    for (int i = 0; i < num_nodes; i++) h_colors[i] = -1;
    
    graphColoring(h_row_ptr, h_col_ind, h_adj_list, h_offset, h_colors, num_nodes);
    for (int i = 0; i < num_nodes; i++) {
        printf("Node %d -> Color %d\n", i, h_colors[i]);
    }
    
    
    return 0;
}
