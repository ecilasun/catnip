# GrimR Manual

## Why the name GrimR?

According to one translation of the Old Nordic word, it means 'person wearing a face mask / helmet'
This sounded suitable for a language which is in fact acting like a 'mask' layer for the underlying Neko CPU, protecting the user from the burden of typing in a lot of assembly code by hand. It's also loosely based on the Brothers Grimm stories, since at times embedded development can get really scary without the proper tools.

## The syntax

The GrimR language syntax is a cross between C/Python/etc where only the parts that matter have been taken.

### Reserved keywords and operators

The following keywords are reserved:
* def
* while
* if
* return
* clf
* fsel
* vsync
* spritesheet
* sprite
* asel

In addition, the following operators are reserved and can't be overriden:
* \* Multiplication
* / Division
* % Modulus
* \+ Addition
* \- Subtraction
* ++ Increment (prefix, without assignment)
* -- Decrement (prefix, without assignment)
* = Assignment
* == Equality
* != Inequality
* ~ Bit Negate
* & And / Address of
* ! Not
* | Or
* ^ Xor
* [] Array Index
* << Bit shift left
* \>\> Bit shift right
