#!/bin/sh

if [ ${1}z = "z" ] 
then 
    export QVERSION=18.1
else
    export QVERSION=$1
fi

export SUMERU_DIR=${HOME}/workspace-vhdl/sumeru

export LIBPNG_PRELOAD=${HOME}/local/lib/libpng12.so

export MAKEFILES=${SUMERU_DIR}/sw/conf/common.mk
export PATH=${PATH}:${SUMERU_DIR}/riscv-gnu-toolchain/bin

export QDIR="${HOME}/local/altera/${QVERSION}/quartus"
export QUARTUS_ROOTDIR_OVERRIDE=${QDIR}
export QSYS_ROOTDIR="${QDIR}/sopc_builder/bin"
export ALTERAOCLSDKROOT="${HOME}/local/altera/${QVERSION}/hld"

export PATH=${PATH}:${QDIR}/bin
export PATH=${PATH}:${HOME}/local/ghdl-0.36-rc1/bin

export _JAVA_OPTIONS=-Dawt.useSystemAAFontSettings=on

alias odump="riscv32-unknown-linux-gnu-objdump -d -M no-aliases"
alias start-pgmw="env LD_PRELOAD=${LIBPNG_PRELOAD} quartus_pgmw"
alias start-quartus="sudo -u root -- unshare -n sudo -u r0h17 env LD_PRELOAD=${LIBPNG_PRELOAD} ${QDIR}/bin/quartus"
