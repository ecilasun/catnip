// Test init declaratiors
int A=2+3*4-8%3, B=3-A/2;
int C[2*4]; // Should contain 2*4 DWORDs of 0xCCCCCCCC
int D[4] = {10, 20, 30, 40};

// NOTE: Actual hardware VRAM starts at 0x80000000, here we cheat for simpler memory access
int *VRAM = 0x10000;

void test()
{
     int E = A*B/-6;          // Should contain 6 at 0x0000000f
     C[2] = 5+D[3];           // Should contain 45 at 0x00000004
     VRAM[4] = 0xFF-C[2];     // Should contain 210 at 0x00010004
     E = &B;                  // E should contain address of B, 0x00000001

     for (int i=2;i<5;i++)
     {
         for (int j=3;j<12;j++)
         {
            E = E + 1;
         }
     }

     return E;
}
