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
alias start-pgmw="sudo -u root -- unshare -n sudo -u r0h17 env LD_PRELOAD=/home/r0h17/local/lib/libpng12.so /home/r0h17/local/altera/19.1/quartus/bin/quartus_pgmw"
alias start-quartus="sudo -u root -- unshare -n sudo -u r0h17 env LD_PRELOAD=${LIBPNG_PRELOAD} ${QDIR}/bin/quartus"

alias quartus_sh_cust="sudo -u root -- unshare -n sudo -u r0h17 ${QDIR}/bin/quartus_sh"
alias quartus_pgmw_cust="sudo -u root -- unshare -n sudo -u r0h17 ${QDIR}/bin/quartus_pgm"
alias quartus_cpf_cust="sudo -u root -- unshare -n sudo -u r0h17 ${QDIR}/bin/quartus_cpf"

export SUMERU_MAKEFILES=${SUMERU_DIR}/sw/conf/sumeru.mk

