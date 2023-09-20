#include <stdio.h>
#include <stdlib.h>

__global__ void dotProd(float *d_a, float *d_b, float *d_c, float *prodVec, int N) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
	
	// element-wise products
	if (tid < N) {
		prodVec[tid] = d_a[tid] * d_b[tid];
	}
	
	// determine amount of padding for parallel reduction
	int padding = 0;
	for (int e = 0; (float)N/(float)(1 << e)>= 1; ++e) {
	      	padding = e + 1;
	}

	for (int i = 0; i < (1 << padding) - N; ++i) {
		prodVec[N + i] = 0;
	}

	__syncthreads();

	// sum using parallel reduction
	for (int stride = 1 << padding; stride >= 1; stride /= 2) {
		if (tid < stride) {
			prodVec[tid] += prodVec[tid + stride];
		}
	}	
	
	__syncthreads();

	d_c[0] = prodVec[0];
}


int main() {
	// var declaration and memory allocation
	int N = 5;
	float *h_a, *h_b, *h_c;
	float *d_a, *d_b, *d_c;
	float *prodVec;

    // memory allocation
	h_a = (float *)malloc(N * sizeof(float));
	h_b = (float *)malloc(N * sizeof(float));
	h_c = (float *)malloc(1 * sizeof(float));

	cudaMalloc((void**)&d_a, N * sizeof(float));
	cudaMalloc((void**)&d_b, N * sizeof(float));
	cudaMalloc((void**)&d_c, 1 * sizeof(float));
	cudaMalloc((void**)&prodVec, 2 * N * sizeof(float));

	// populate vectors with data	
	for (int i = 0; i < N; ++i) {
		h_a[i] = (float) (rand() % 10 + 1);
		h_b[i] = (float) (rand() % 10 + 1);
	}

	cudaMemcpy(d_a, h_a, N * sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, h_b, N * sizeof(float), cudaMemcpyHostToDevice);
	
	// launch kernel instance
	dotProd<<<1, N>>>(d_a, d_b, d_c, prodVec, N);
	
	// copy results to CPU
	cudaMemcpy(h_c, d_c, 1 * sizeof(float), cudaMemcpyDeviceToHost);

    // print results
	printf("A:\n--------\n");
        for(int i = 0; i < N; ++i) {
                printf("%f ", h_a[i]);
                printf("\n");
        }
      
        printf("--------\n");
        printf("B:\n--------\n");
        for(int i = 0; i < N; ++i) {
                printf("%f ", h_b[i]);
                printf("\n");
        }
        
        printf("--------\n");
        printf("C:\n");
        printf("%f ", h_c[0]);
        printf("\n--------\n");

	// clean up memory
	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_c);

	free(h_a);
	free(h_b);
	free(h_c);

	return 0;
}
