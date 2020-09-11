#include "catnip.h"

int main(int _argc, char **_argv)
{
	if (_argc<=1)
	{
		printf("catnip v0.2\n");
		printf("(C)2020 Engin Cilasun\n");
		printf("Usage:\n");
		printf("catnip inputfile.grm outputfile.asm - Generates assembly listing from GrimR code\n");
		printf("catnip inputfile.asm outputfile.mif - Generates a memory initialization file from assembly input for FPGA device\n");
		printf("catnip inputfile.asm outputfile.rom - Generates a ROM file from assembly input for emulator\n");
		printf("catnip inputfile.rom - Runs the emulator with given ROM file\n");
		return 0;
	}

	if (strstr(_argv[1], ".grm"))
		return CompileCode(_argv[1], _argv[2]);		// .GrimR -> .ASM
	else if (strstr(_argv[1], ".asm"))
		return compile_asm(_argv[1], _argv[2]);		// .ASM -> .ROM/.MIF
	else
		return emulate_rom(_argv[1]);				// .ROM -> Emulator
}
