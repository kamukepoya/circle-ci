#!/bin/bash

export KERNELNAME=Sea-Kernel

send_msg "⏳ Start building ${KERNELNAME} | DEVICE: Merlinx / Merlin"

START=$(date +"%s")

source compiler/clang/Gclang.sh

source compiler/clang/GPKclang.sh

END=$(date +"%s")

DIFF=$(( END - START ))

send_msg "✅ Build completed in $((DIFF / 60))m $((DIFF % 60))s"

