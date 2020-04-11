/* Simple VRAM access test */

byte testsprite[16]={0x00,0xFF,0xFF,0xFF,0x00,0xFF,0x00,0xFF,0x00,0xFF,0x00,0xFF,0x00,0xFF,0x00,0xFF};
/* Above should compile to:
   @org ????
   @label testsprite
   @dw 0x00ff 0x00ff 0x00ff 0x00ff 0x00ff 0x00ff 0x00ff 0x00ff
   Read to r0 (r0=testsprite[idx]): lea r1, testsprite; ld.w r1, [r1]; ld.w r2, idx; iadd r1, r2; {retire r2} ld.b r0, [r1]
   Write from r0 (testsprite[idx]=r0): lea r1, testsprite; ld.w r1, [r1]; ld.w r2, idx; iadd r1, r2; {retire r2} st.b [r1], r0 */

byte *VRAM = 0x80000000;
/* Above should compile to:
   @org ????
   @label VRAM
   @dw 0x8000000
   Read to r0 (r0=VRAM[idx]): lea r1, VRAM; ld.w r1, [r1]; ld.w r2, idx; iadd r1, r2; {retire r2} ld.b r0, [r1] {NOTE In practice Neko can't read from VRAM}
   Write from r0 (VRAM[idx]=r0): lea r1, VRAM; ld.w r1, [r1]; ld.w r2, idx; iadd r1, r2; {retire r2} st.b [r1+idx], r0 */

void draw_block(word x, word y)
{
  word ix;
  word iy;
  for (iy = y; iy < y + 16; iy = iy + 1)
  {
    for (ix = x; ix < x + 16; ix = ix + 1)
    {
        /*asm
        {
          ldw r0, [ix]
          ldw r1, [iy]
          ldw r2, 0x100
          imul r1, r2
          iadd r0, r1
          ldw r1, 0x80000000
          iadd r0, r1
          stb [r0], 0xFF
        };*/
        VRAM[ix+iy*256] = testsprite[ix%16];
    }
  }
}

void main() {
  draw_block(64, 16);
  draw_block(32, 48);
}
