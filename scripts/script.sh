#!/bin/bash

echo "Open a new terminal and use the following command: sudo cat /sys/kernel/debug/tracing/trace"

if test -f ../src/user/user; then
    rm ../src/user/user
fi

if test -f ../src/kern.exec.o; then
    rm ../src/kern/exec.o
fi

bpftool btf dump file /sys/kernel/btf/vmlinux format c > ../src/kern/vmlinux.h
clang -g -D__TARGET_ARCH_x86 -mlittle-endian -Wno-compare-distinct-pointer-types -O2 -target bpf -emit-llvm -c ../src/kern/exec.c -o - | llc -march=bpf -mcpu=v2 -filetype=obj -o ../src/kern/exec.o;

bpftool gen skeleton ../src/kern/exec.o > ../src/user/exec.skel.h
gcc -g ../src/user/user.c -o ../src/user/user -I$HOME/libbpf/src/ $HOME/libbpf/src/libbpf.a -lelf -lz

sudo ../src/user/user
