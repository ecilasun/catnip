#include "catnip.h"

int main(int _argc, char **_argv)
{
	bool forX64 = false;
	if (_argc<=1)
	{
		printf("catnip v0.2\n");
		printf("(C)2020 Engin Cilasun\n");
		printf("Usage:\n");
		printf("catnip [-forX64] inputfile.grm outputfile.asm - Generates assembly listing from GrimR code\n");
		printf("catnip [-forX64] inputfile.asm outputfile.mif - Generates a memory initialization file from assembly input for FPGA device\n");
		printf("catnip [-forX64] inputfile.asm outputfile.rom - Generates a ROM file from assembly input for emulator\n");
		printf("catnip [-forX64] inputfile.grm outputfile.rom - Directly compiles GrimR into a ROM file\n");
		printf("catnip [-forX64] inputfile.grm outputfile.mif - Directly compiles GrimR into a memory initialization file for FPGA device\n");
		printf("catnip [-forX64] inputfile.grm - Compiles/assembles and emulates GrimR code in one step\n");
		printf("catnip [-forX64] inputfile.rom - Runs the emulator with given ROM file\n");
		return 0;
	}

	int retVal = 0;
	int argindex = 1;
	if (strstr(_argv[1], "-forX64"))
	{
		forX64 = true;
		argindex = 2;
	}

	if (strstr(_argv[argindex], ".grm"))
	{
		if (_argc>=3)
		{
			if (strstr(_argv[argindex+1], ".asm"))
			{
				retVal = CompileGrimR(_argv[argindex], _argv[argindex+1], forX64);		// .GrimR -> .ASM
			}
			else
			{
				const char *tmpfile = tmpnam(nullptr);
				retVal = CompileGrimR(_argv[argindex], tmpfile, forX64);		// .GrimR -> .ROM/.MIF
				if (retVal==0)
					retVal = AssembleBinary(tmpfile, _argv[argindex+1]);
				// Remove the temporary file
				remove(tmpfile);
			}
		}
		else	// .GrimR -> Emulator
		{
			const char *tmpfile1 = tmpnam(nullptr);
			const char *tmpfile2 = tmpnam(nullptr);
			char asmfilename[512] = "";
			strcat(asmfilename, tmpfile1);
			strcat(asmfilename, ".asm");
			char romfilename[512] = "";
			strcat(romfilename, tmpfile2);
			strcat(romfilename, ".rom");
			retVal = CompileGrimR(_argv[argindex], asmfilename, forX64);		// .GrimR -> .ROM/.MIF
			if (retVal==0)
			{
				if (forX64)
				{
					retVal = AssembleBinaryX64(asmfilename, romfilename);
					// TODO: Run the .exe
				}
				else
				{
					retVal = AssembleBinary(asmfilename, romfilename);
					//if (retVal==0)
						retVal = EmulateROMImage(romfilename);
				}
			}
			// Remove the temporary files
			remove(asmfilename);
			remove(romfilename);
		}
	}
	else if (strstr(_argv[argindex], ".asm"))
	{
		if (forX64)
			retVal = AssembleBinaryX64(_argv[argindex], _argv[argindex+1]);		// .ASM -> .EXE for PC/Windows
		else
			retVal = AssembleBinary(_argv[argindex], _argv[argindex+1]);		// .ASM -> .ROM/.MIF
	}
	else
	{
		// if (forX64) -> Simply run the .exe instead
		retVal = EmulateROMImage(_argv[argindex]);								// .ROM -> Emulator
	}

	return retVal;
}
