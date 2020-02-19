# sumeru
  An open-source RISC-V CPU core and hardware platform for Altera Cyclone-IV FPGAs.

## Coremark Performance

### Summary

Sumeru @ 75 MHz - 3 stage pipeline - 4K ICACHE 4K DCACHE - MEM STACK

Compiler Flag | Binary Size | Result
------------- | ----------- | ------
-Os | 11784 | 100
-O | 13008 | 105
-O2 | 13092 | 133
-O3 | 16280 | 143

** MEM MALLOC and MEM STATIC performance is similar


### Detail

```
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 1165127873
Total time (secs): 15
Iterations/Sec   : 133
Iterations       : 2000
Compiler version : 9.2.0
Compiler flags   : -O2
Memory location  : STACK
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x4983
Correct operation validated. See README.md for run and reporting rules.


2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 1165095923
Total time (secs): 15
Iterations/Sec   : 133
Iterations       : 2000
Compiler version : 9.2.0
Compiler flags   : -O2
Memory location  : BSS
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x4983
Correct operation validated. See README.md for run and reporting rules.


2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 1165033531
Total time (secs): 15
Iterations/Sec   : 133
Iterations       : 2000
Compiler version : 9.2.0
Compiler flags   : -O2
Memory location  : HEAP
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x4983
Correct operation validated. See README.md for run and reporting rules.
```

[Altera NIOS II CycloneIII](https://www.eembc.org/coremark/view.php?benchmark_seq=1535)
[Altera Nios II - 80](https://www.eembc.org/coremark/view.php?benchmark_seq=1336)
[Altera Nios II - 200 MHz](https://www.eembc.org/coremark/view.php?benchmark_seq=1486)
[Altera Nios II - 200 MHz](https://www.eembc.org/coremark/view.php?benchmark_seq=1487)
[Altera Nios II/f - 100 MHz](https://www.eembc.org/coremark/view.php?benchmark_seq=2483)

[Xilinx MicroBlaze v7.20.d in Spartan XC3S700A FPGA, 3-stage pipeline, 2K/2K cache](https://www.eembc.org/coremark/view.php?benchmark_seq=1042)
[Xilinx MicroBlaze v7.20.d in Spartan XC3S700A FPGA, 5-stage pipeline, 4K/4K cache, integer divider, barrel shifter](https://www.eembc.org/coremark/view.php?benchmark_seq=1043)
[Xilinx MicroBlaze 7.10d in Virtex4-FX20 FPGA, 5-stage pipeline, 16K/16K cache](https://www.eembc.org/coremark/view.php?benchmark_seq=1287)
[Xilinx MicroBlaze v8.20.b in Virtex5 FPGA, 5-stage pipeline, 16K/16K cache](https://www.eembc.org/coremark/view.php?benchmark_seq=1345)

[Coremark Results Website](https://www.eembc.org/coremark/scores.php)
