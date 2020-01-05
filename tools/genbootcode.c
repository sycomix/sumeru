#include <stdio.h>
#include <stdint.h>

int
main(int argc, char **argv)
{
    unsigned short addr, data, checksum, cb;


    for (addr = 0; addr < 1024; ++addr) {
        if (fread(&data, sizeof(data), 1, stdin) != 1)
            data = 0;

        checksum = 0;
        checksum += 2;
        checksum += addr & 0xff;
        checksum += (addr & 0xff00) >> 8;
        checksum += data & 0xff;
        checksum += (data & 0xff00) >> 8;
        cb = checksum & 0xff;
        cb = (~cb + 1) & 0xff;

        printf(":02%04X00%04X%02X\n", addr, data, cb);
    }
    printf(":00000001FF\n");
    return 0;
}
