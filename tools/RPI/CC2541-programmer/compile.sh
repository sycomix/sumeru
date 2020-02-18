SRCFILES="main.c"
gcc -o CC2541-programmer $SRCFILES -lbcm2835
sudo setcap 'CAP_SYS_NICE=ep' "$(pwd)/CC2541-programmer"
