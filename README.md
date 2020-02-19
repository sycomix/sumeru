# sumeru
  An open-source RISC-V CPU core and hardware platform for Altera Cyclone-IV FPGAs.

## Coremark Performance

### Summary

Sumeru @ 75 Mhz - MEM STACK

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

[Coremark Results Website -- explore similar performance CPUs](https://www.eembc.org/coremark/scores.php)
