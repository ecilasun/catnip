# CatNip

CatNip is an assembler and emulator that generates code from a custom CPU used in Project Neko, and can emulate the generated binary as close to hardware as possible.

## Building the assembler/emulator

### Visual Studio Code
If you're using Visual Studio Code, this folder contains a .vscode directory with necessary setup files that will allow you to build and run CatNip. Simply follow these steps:

* Start Visual Studio Code
* Open the root folder of CatNip
* First time around, use Ctrl+Shift+B and select 'configure' from the menu
* For first time around, and all subsequent builds related to any code change, use Ctrl+Shift+B and select 'build' from the menu

### Command line
WAF (the build system) is included with this release. To build CatNip from command line, run these from the root directory where you've placed the catnip project.

If you happen to be building on Linux, before everything else you'll need to install clang and SDL2 libraries as follows:
```
sudo apt install clang
sudo apt install libsdl2-dev
sudo apt install bison
sudo apt install flex
sudo apt install re2c
```

For first time around, or if you change the wscript's configure or options functions, a configuration step is required:
```
python waf --out='build/release' configure
```

After that, any further code builds require only the following:
```
python waf build
```

## Running CatNip

To assemble a source file into a ROM image, assuming you're at the root directory of the repository, use the following from the command line:

```
.\build\release\catnip.exe .\test\video.asm .\test\video.rom
```

To emulate the generated ROM file, assuming you're at the root directory of the repository, use the following from the command line:

```
.\build\release\catnip.exe .\test\video.rom
```

To compile a .c file into an .asm file, use the following command line:

```
.\build\release\catnip.exe .\test\simplest.c .\tes\simplest.asm
```

## Known issues / notes regarding C compiler

Catnip includes a very small subset of C that it can compile into asm for convenience. However this compiler is still under development and doesn't currently work fully. Here's a list of notes regarding what currently works and what doesn't work:

* Preprocessor: There are no preprocessor directives yet (#include, #define etc)
* Parser: Tokenizing works to full capacity
* Symbols: There's a very basic 64K pool for initial variable values at the moment
* AST: The AST generator does a very minimal job currently
  * Can parse variable generation and initial value assignments (including initializer lists) for byte/word/dword and byteptr/wordptr types
  * Can distinguish between function declaration and variable definitions
  * Can report some basic errors
  * Will currently not detect missing initial value in variable declarations
* Assembly: The code generator is not implemented yet, as it depends on a full, well formed AST
* Linker: Currently only a single translation unit is compiled and there's no file include support

## Emulator shortcuts

The emulator can be shut down using the `ESC` key.

To 'reset' the CPU, you can hit the `SPACE` key which will rewind CPU state to INIT and restart your program.

## Known issues

CatNip emulator will currently not give warnings about code execution errors, neither it will do safety checks while executing code, which might result in the emulator to unexpectedly shut down.

The CPU timing is not accurate, so your software might run a little faster than it should. However, the timing between the VGA module and the CPU is somewhat close to the actual hardware, though it still requires fine tuning.

The CPU emulation actually emulates all the state machine stages of Neko CPU, therefore it should be as close as possible to the actual hardware in its capabilities.

## 3rd party libraries / tools

This project currently uses WAF as its build system for portability, and SDL2 as its graphics output, which might change in the future.
