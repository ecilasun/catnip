/* Compiler/parser test */

word testglobal;

byteptr VRAM = 0x80000000;
/* Above should compile to:
   @org ????
   @label VRAM
   @dw 0x8000000
   Read to r0 (r0=VRAM[idx]): lea r1, VRAM; ld.w r1, [r1]; ld.w r2, idx; iadd r1, r2; {retire r2} ld.b r0, [r1] {NOTE In practice Neko can't read from VRAM}
   Write from r0 (VRAM[idx]=r0): lea r1, VRAM; ld.w r1, [r1]; ld.w r2, idx; iadd r1, r2; {retire r2} st.b [r1+idx], r0 */

byte testsprite[16] = {0x00,0x02,0x04,0x06, 0x08,0x0A,0x0C,0x0E,0x10,0x12,0x14,0x18,0x1A,0x1C,0x1E,0x20};
/* Above should compile to:
   @org ????
   @label testsprite
   @dw 0x00ff 0x00ff 0x00ff 0x00ff 0x00ff 0x00ff 0x00ff 0x00ff
   Read to r0 (r0=testsprite[idx]): lea r1, testsprite; ld.w r1, [r1]; ld.w r2, idx; iadd r1, r2; {retire r2} ld.b r0, [r1]
   Write from r0 (testsprite[idx]=r0): lea r1, testsprite; ld.w r1, [r1]; ld.w r2, idx; iadd r1, r2; {retire r2} st.b [r1], r0 */

void draw_block(word x, word y)
{
  word ix;
  word iy;
  for (iy = y; iy <= y + 15; iy = iy + 1)
  {
    for (ix = x; ix <= x + 15; ix = ix + 1)
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

void main(){
  testglobal = 0;
  if (testglobal >= 0)
  {
    draw_block(64, 16);
    draw_block(32, 48);
  }
}
