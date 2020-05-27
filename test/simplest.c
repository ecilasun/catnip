void Find(char c, char* s)
{
	return *s ? *s==c ? 1 : find(c, s+1) : 0;
}

int Length(char *s)
{
	int result=0;
	while(*s++)
	{
		++result;
	}
	return result;
}

char LastCharN(char *s, int n)
{
	return s[Length(s)-n];
}
