# CatNip

CatNip is a compiler/assembler/emulator triplet that generates code for a custom CPU used in Project Neko, and can emulate the generated binary as close to hardware as possible. It can either accept asm input or input in the form of the language GrimR.

## Building the assembler/emulator

### Visual Studio Code
If you're using Visual Studio Code, this folder contains a .vscode directory with necessary setup files that will allow you to build and run CatNip. Simply follow these steps:

* Start Visual Studio Code
* Open the root folder of CatNip
* First time around, use Ctrl+Shift+B and select 'configure' from the menu
* For first time around, and all subsequent builds related to any code change, use Ctrl+Shift+B and select 'build' from the menu

### Command line
WAF (the build system) is included with this release. To build CatNip from command line, run these from the root directory where you've placed the catnip project.

If you happen to be building on Linux or MacOS, before everything else you'll need to install clang and SDL2 libraries as follows:
```
sudo apt install clang
sudo apt install libsdl2-dev
```

Additionally you'll be needing the bison and flex packages on Linux or MacOS. At the time of writing I found that they were pre-installed on my MacOS, your setup might be different. As a build aid, bison and flex are already provided as binaries in the directory 'buildtools' for Windows.

Therefore for Linux/MaxOS one needs to run the following to complete the build setup:
```
sudo apt install bison
sudo apt install flex
```

P.S. I might make the WAF system actually set up things for the end user at a later point.

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

To compile a .grm file into an .asm file, use the following command line:

```
.\build\release\catnip.exe .\test\simplest.grm .\tes\simplest.asm
```

Alternatively, you can use the following shortcut to directly compile and launch a temporary ROM image from an input .grm file:

```
.\build\release\catnip.exe .\test\simplest.grm
```

Please use catnip.exe without any input parameters for a full list of command line options.

## Emulator shortcuts

The emulator can be shut down using the `ESC` key.

To 'reset' the CPU, you can hit the `SPACE` key which will rewind CPU state to INIT and restart your program.

## Known issues

CatNip emulator will currently not give warnings about code execution errors except illegal instructions, neither it will do safety checks while executing code, which might result in the emulator to unexpectedly shut down.

Also, the CPU timing is not 1:1 yet, therefore your software might run a little faster than it should. However, the timing between the VGA module and the CPU is somewhat close to the actual hardware, though it still requires fine tuning.

The CPU emulation actually emulates all the state machine stages of Neko CPU, therefore it should be as close as possible to the actual hardware in its capabilities.

## 3rd party libraries / tools

This project currently uses WAF as its build system for portability, and SDL2 as its graphics output, which might change in the future. For the compiler, bison and flex tools are either provided (for Windows), or expected to be installed by the user (Linux/MacOS) to generate the grammar code for the language GrimR.

## The instruction set for Neko

You can find a detailed instruction set manual here: [Neko Instruction Set](https://github.com/ecilasun/catnip/blob/master/INSTRUCTION_SET.md)

## About GrimR

The language GrimR is a very simple one. It's sole purpose is to run on very simple embedded systems with no dynamic memory allocation, with no code relocation possible. A typical scenario is an FPGA device like Neko where the memory is very limited and is made of SRAM resources or internal FPGA block memory, with address decoder providing facilities to route memory access to either the SRAM or to VRAM for video output.
In such a scenario, GrimR tries to provide only the most basic support as a high level language versus having to type in manual assembly, and might not be as powerful as C or any other language just yet.
In time, more features will be added as long as they stay within the above limitations.
For the time being you can refer to this manual for GrimR reference: [GrimR Manual](https://github.com/ecilasun/catnip/blob/master/GRIMR.md)
