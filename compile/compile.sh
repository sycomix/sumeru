#!/bin/bash

#WWW: https://riscv.org/software-tools/risc-v-gnu-compiler-toolchain/

#sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

cd `dirname $0`

git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
export BASEDIR=/home/r0h17/workspace-vhdl/sumeru/riscv-gnu-toolchain
export PATH=${PATH}:${BASEDIR}/bin
pushd riscv-gnu-toolchain
./configure --prefix=${BASEDIR} --with-arch=rv32ima |& tee ../configure.log && make linux |& tee ../build.log
