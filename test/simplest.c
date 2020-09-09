// Test init declaratiors
int A=2+3*4-8%3, B=3-A/2;
int C[2*4]; // Should contain 2*4 DWORDs of 0xCCCCCCCC
int D[4] = {10, 20, 30, 40};

// NOTE: Actual hardware VRAM starts at 0x80000000, here we cheat for simpler memory access
int *VRAM = 0x10000;

int beta(int a)
{
    int i = a*8;
    return i;
}

void test()
{
    int E = A*B/-6;          // Should contain 6 at 0x0000000f
    C[2] = 5+D[3];           // Should contain 45 at 0x00000004
    VRAM[4] = 0xFF-C[2];     // Should contain 210 at 0x00010004
    E = &B;                  // E should contain address of B, 0x00000001

    A = beta(1);

    for (int y=2;y<10;y++)
    {
        for (int x=8;x<16;x++)
        {
           int addrs = x + y*320; // For 320x240 framebuffer
           VRAM[addrs] = 0xFF;
        }
    }
    return;
}

void meh()
{
    return;
}
