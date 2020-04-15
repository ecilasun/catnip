/* Compiler/parser test */

unsigned short testglobal;

char VRAM = 0x80000000;

char testsprite[16] = {0x00,0x02,0x04,0x06,0x08,0x0A,0x0C,0x0E,0x10,0x12,0x14,0x18,0x1A,0x1C,0x1E,0x20};

void drawblock(unsigned short x, unsigned short y)
{
  unsigned short ix;
  unsigned short iy;
  for (iy = y; iy <= y + 15; iy = iy + 1)
  {
    for (ix = x; ix <= x + 15; ix = ix + 1)
    {
         VRAM[ix+iy*256] = testsprite[ix%16];
    }
  }
}

void main()
{
  testglobal = 0;
  if(testglobal >= 0)
  {
    drawblock(64,16);
    drawblock(32,48);
  }
}
