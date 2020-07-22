# hawk

## Overview

In this short tutorial you will learn how to write and compile a simple **BPF program** that performs **bpf_trace_printk**. The program will be loaded into the kernel and will print a string after the execution of each process.

You need two C files, which can be found in */src*:

**exec.c** (the file that contains the BPF program)
- SEC(str): shows what LSM hook to use to attach to the kernel
- int BPF_PROG(): the actual code for the BPF program that is executed

**user.c** (the file that contains the userspace program that loads the BPF program into the kernel using libbpf)
- the main function in which the BPF program is opened, loaded and attached to the kernel

## Setup

Start by cloning this repo:
```
git clone https://github.com/Poppy22/hawk.git
```

**Linux kernel**

Get the latest version of the Linux kernel:
```
git clone https://github.com/torvalds/linux.git
```

Install the following packages:
```
sudo apt install -y \
  qtdeclarative5-dev \
  pkg-config \
  bison \
  flex \
  libelf-dev \
  llvm \
  ccache
```

In the linux/ folder, create the kernel configuration:
```
make defconfig
```

Expected output:
```
*** Default configuration is based on 'x86_64_defconfig'
#
# configuration written to .config
#
```

Now compile the kernel and wait (this could take a few minutes):
```
make -j `nproc`
```
Expected output:
```
[many lines]
  AS      arch/x86/boot/header.o
  LD      arch/x86/boot/setup.elf
  OBJCOPY arch/x86/boot/setup.bin
  BUILD   arch/x86/boot/bzImage
Setup is 13948 bytes (padded to 14336 bytes).
System is 8720 kB
CRC 6831e9de
Kernel: arch/x86/boot/bzImage is ready  (#2)
```

**bpf**

After compiling the kernel, install bpf.
```
cd linux/tools/libs/bpf
make
sudo make install prefix=/usr
```

**[bpftool](https://www.mankier.com/8/bpftool)**

This is a tool for inspection and simple manipulation of BPF programs.
```
cd linux/tools/bpf/bpftool
make
sudo make install
```

**[libbpf-dev](https://packages.debian.org/sid/libbpf-dev)**

This package is needed to compile programs which use libbpf.
```
sudo apt install libbpf-dev
```

## Aliases

You probably worked with gcc (C compiler) before. This time, we need some special advanced commands to compile the BPF program, which we’ll call **kcc** (k stands for kernel) and **ucc** (u stands for user).

In your home directory, open .bashrc:
```
cd
vim .bashrc
```

Introduce aliases for the following commands:
```
__kcc()
{
  clang -g -D__TARGET_ARCH_x86 -mlittle-endian -Wno-compare-distinct-pointer-types -O2 -target bpf -emit-llvm -c $1 -o - | llc -march=bpf -mcpu=v2 -filetype=obj -o "$(basename  $1 .c).o";

}
alias kcc=__kcc

__ucc ()
{
    gcc -g $1 -o "$(basename $1 .c)" -I$HOME/libbpf/src/ $HOME/libbpf/src/libbpf.a -lelf -lz
}
alias ucc=__ucc
```
Restart your terminal now.

## Compile the BPF program

Go to hawk/src/exec and look for a file called `vmlinux.h`. If there is no such file, you can generate it with the command:
```
bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
```

Compile exec.c:
```
kcc exec.c
```

Go to hawk/src/user and check for a fille called `exec.skel.h`. If there is no such file, you can generate it by typing the next command in the /src/exec/ folder:
```
bpftool gen skeleton exec.o > ../user/exec.skel.h
```

Compile user.c
```
ucc user.c
```

## Run the BPF program
In /hawk/src/user, run the following command:
```
sudo ./user
```

Open a new terminal and type:
```
sudo cat /sys/kernel/debug/tracing/trace
```
The expected output is:
```
# tracer: nop
#
# entries-in-buffer/entries-written: 3840/3840   #P:8
#
#                              _-----=> irqs-off
#                             / _----=> need-resched
#                            | / _---=> hardirq/softirq
#                            || / _--=> preempt-depth
#                            ||| /     delay
#           TASK-PID   CPU#  ||||    TIMESTAMP  FUNCTION
#              | |       |   ||||       |         |
 systemd-journal-670   [001] .... 169963.290258: 0: openat read only
           <...>-418471 [005] .... 169963.290265: 0: openat read only
 systemd-journal-670   [001] .... 169963.290307: 0: openat read only
 systemd-journal-670   [001] .... 169963.290361: 0: openat read only
 systemd-journal-670   [001] .... 169963.290409: 0: openat read only
           <...>-816923 [005] .... 327070.899408: 0: openat read only
           <...>-664639 [004] .... 327070.899408: 0: openat read only
           <...>-664639 [004] .... 327070.899471: 0: openat read only
           <...>-664639 [004] .... 327070.899527: 0: openat read only
           <...>-1677604 [004] .... 693150.730117: 0: hello
           <...>-1677607 [005] .... 693152.316666: 0: hello
           <...>-1677614 [005] .... 693152.731883: 0: hello
           <...>-1677620 [003] .... 693152.761767: 0: hello
           <...>-1677621 [006] .... 693152.763810: 0: hello
           <...>-1677621 [000] .... 693152.764590: 0: hello
 ```
 
 Notice how some processes printed "hello", which is what the BPF program was meant to do.
 
 **Congrats**, you compiled your first BPF program! 🎉
