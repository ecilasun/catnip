{
	var A, B;
	A = 2;
	var R[2*A];

	{
		var D;
		D = 3;
		B = 5+A;
		R[0] = 0x7FFF/(3*(A-4)+B);
		R[1] = R[0]*2;
	}

	{
		// Test: D should be out of scope here since it's in another code block's scope
		//A = D+1;

		// Test: Both A and B should still be accessible from outer scope
		{
			A = B+R[1];
		}
	}
}

