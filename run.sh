#!/bin/bash
set -xue

# QEMU file path
QEMU=qemu-system-riscv32

OBJCOPY=/opt/homebrew/opt/llvm/bin/llvm-objcopy
CC=/opt/homebrew/opt/llvm/bin/clang
CFLAGS="-std=c11 -O2 -g3 -Wall -Wextra --target=riscv32 -ffreestanding -nostdlib"

# Build the shell (application)
$CC $CFLAGS -Wl,-Tuser.ld -Wl,-Map=shell.map -o shell.elf shell.c user.c common.c
$OBJCOPY --set-section-flags .bss=alloc,contents -O binary shell.elf shell.bin
$OBJCOPY -Ibinary -Oelf32-littleriscv shell.bin shell.bin.o

# Build the kernel
$CC $CFLAGS -Wl,-Tkernel.ld -Wl,-Map=kernel.map -o kernel.elf \
    kernel.c common.c shell.bin.o

# -bios default: Use the default firmware (OpenSBI in this case).
# -nographic: Start QEMU without a GUI window.
# -serial mon:stdio: Connect QEMU's standard input/output to the virtual machine's serial port. 
# Specifying mon: allows switching to the QEMU monitor by pressing Ctrl+A then C.
# --no-reboot: If the virtual machine crashes, stop the emulator without rebooting (useful for debugging).
$QEMU -machine virt -bios default -nographic -serial mon:stdio --no-reboot \
    -kernel kernel.elf
