find c,s:		{ return *s ? *s==c ? 1 : find(c, s+1) : 0; }
Length s:		{ var result=0; while(*s++) {++result;} return result; }
LastCharN s,n:	return s[Length(s)-n];
