// Simple VRAM access test

uchar *VRAM = 0x80000000;

void draw_block(ushort x, ushort y)
{
  ushort ix;
  ushort iy;
  for (iy = y; iy < y + 16; iy = iy + 1)
  {
    for (ix = x; ix < x + 16; ix = ix + 1)
    {
        VRAM[ix+iy*256] = 0xFF;
    }
  }
}

void main() {
  draw_block(64, 16);
  draw_block(32, 48);
}
