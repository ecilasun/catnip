{
	var A, B;
	A = 1;
	var testarray[2*A];

	{
		var D;
		D = 3;
		B = 5+A;
		testarray[0] = 1+0x7FFF/(3*(A-4)+2*B);
		testarray[1] = testarray[0]*2;
	}

	{
		// Test: D should be out of scope here since it's in another code block's scope
		//A = D+1;

		// Test: Both A and B should still be accessible from outer scope
		{
			A = B+(testarray[1]+testarray[0])/2;
		}
	}
}

