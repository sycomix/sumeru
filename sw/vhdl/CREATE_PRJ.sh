#!/bin/bash

if [ ${1}x == x ] 
then
    echo "Usage: $0 <prj_name>"
    exit 1
fi

mkdir $1
cp ${SUMERU_DIR}/sw/vhdl/SKEL/* $1
cd $1
sed -i  -e "s/%%SKEL_PRJNAME%%/$1/g" *
for fn in *
do
        nfn=`echo $fn | sed -e "s/skel/${1}/g"`
        if [ "$fn" != "$nfn" ]
        then
            mv "$fn" "$nfn"
        fi
done
