#!/bin/bash

#WWW: https://riscv.org/software-tools/risc-v-gnu-compiler-toolchain/

cd `dirname $0`

git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
export BASEDIR=/home/r0h17/workspace-vhdl/sake/riscv-gnu-toolchain
export PATH=${PATH}:${BASEDIR}/bin
pushd riscv-gnu-toolchain
./configure --prefix=${BASEDIR} --with-arch=rv32ima |& tee ../configure.log && make linux |& tee ../build.log
