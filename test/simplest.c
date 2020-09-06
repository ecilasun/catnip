// Test init declaration: A=12, B=-3
int A=2+3*4-8%3, B=3-A/2;
int C[2*4];
int D[4] = {10,20,30,40};
int *VRAM = 0x10000;

int test()
{
     int E = A*B/-6;
     E = 2+E;
     VRAM[3] = 0xFF;
}
