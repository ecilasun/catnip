/*
Compiler/parser test
*/

word testglobal;

byte *VRAM = 0x80000000;

byte testsprite[16] = {0x00,0x02,0x04,0x06,0x08,0x0A,0x0C,0x0E,0x10,0x12,0x14,0x18,0x1A,0x1C,0x1E,0x20};

byte *teststring = "someliteral";

void drawblock(word x, word y)
{
	word ix;
	word iy;
	for (iy = y; iy <= y + 15; iy = iy + 1)
	{
		for (ix = x; ix <= x + 15; ix = ix + 1)
		{
			VRAM[ix+(iy*256)] = testsprite[ix%16];
		}
	}
}

int main()
{
	testglobal = 0;
	if(testglobal < absurdity) // Note: this should fail at compile time
	{
		drawblock(64,16);
		drawblock(32,48);
	}

	return 0;
}
