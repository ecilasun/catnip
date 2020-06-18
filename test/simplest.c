void main(void)
{
	int A, B;
	A = 1;
	int testarray[2*A];

	if (A!=0)
	{
		int D;
		D = 3;
		B = 5+A;
		testarray[0] = 1+0x7FFF/(3*(A-4)+2*B);
		testarray[1] = testarray[0]*2 + testFunc();
	}

	A = B+(testarray[1]+testarray[0])/2;
}

