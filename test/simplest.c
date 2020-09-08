// Test init declaratiors
int A=2+3*4-8%3, B=3-A/2;
int C[2*4]; // Should contain 2*4 DWORDs of 0xCCCCCCCC
int D[4] = {10, 20, 30, 40};

// NOTE: Actual hardware VRAM starts at 0x80000000, here we cheat for simpler memory access
int *VRAM = 0x10000;

int test()
{
     int E = A*B/-6;
     C[2] = 5+D[3];
     VRAM[4] = 0xFF-C[2];     // Should receive 210 at 0x00010004
     E = &B;                  // E should contain address 0x00000001
}
