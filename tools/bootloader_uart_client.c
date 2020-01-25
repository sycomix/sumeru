#include <stdio.h>
#include <unistd.h>
#include <err.h>
#include <string.h>
#include <fcntl.h>
#include <stdlib.h>

char *code_fname = "a.out";
char *dev_fname = "/dev/ttyUSB0";
unsigned char *load_address = (unsigned char *)0x10000;
unsigned char *jmp_address = (unsigned char *)0x10000;


void
process_cmdline_args(int argc, char **argv)
{
    while (1) {
        switch (getopt(argc, argv, "f:d:l:j:")) {
            case 'f':
                code_fname = strdup(optarg);
                break;
            case 'd':
                dev_fname = strdup(optarg);
                break;
            case 'l':
                load_address = (unsigned char*)strtoul(optarg, 0, 0);
                break;
            case 'j':
                jmp_address = (unsigned char*)strtoul(optarg, 0, 0);
                break;
            case -1:
                return;
            default:
                errx(1, "Usage: %s [-f bootcode] [-d device] "
                        "[-l load_address] [-j jmp_address]", argv[0]);
        }
    }
}

void
set_address(int dev, unsigned char *address)
{
    char buf[16];

    buf[0] = 'a';
    memcpy(buf + 1, &address, 4);
    buf[5] = buf[1] ^ buf[2] ^ buf[3] ^ buf[4];
    write(dev, buf, 6);
    read(dev, buf, 1);
    if (buf[0] != 'O')
        errx(1, "Error setting address: %x", (int)buf[0]);
}

void
initiate_jmp(int dev, unsigned char *address)
{
    char buf[16];

    buf[0] = 'j';
    write(dev, buf, 1);
    read(dev, buf, 1);
    if (buf[0] != 'O')
        errx(1, "Error initiating jmp");
}


void
write_data(int dev, char *data)
{
    char buf[16];

    buf[0] = 'w';
    memcpy(buf + 1, data, 4);
    buf[5] = buf[1] ^ buf[2] ^ buf[3] ^ buf[4];
    write(dev, buf, 6);
    read(dev, buf, 1);
    if (buf[0] != 'O')
        errx(1, "Error writing data: %x", (int)buf[0]);

}


int
main(int argc, char **argv)
{
    char buf[4];
    int fd, dev, rcount, wcount;

    process_cmdline_args(argc, argv);

    if ( (fd = open(code_fname, O_RDONLY, 0)) < 0) {
        errx(1, "Error opening: %s", code_fname);
    }
    if ( (dev = open(dev_fname, O_RDWR, 0)) < 0) {
        errx(1, "Error opening: %s", dev_fname);
    }

    warnx("Device: %s", dev_fname);
    warnx("Loading code file: %s", code_fname);
    warnx("Load Address: 0x%x: Jump Address: 0x%x", load_address, jmp_address);
    set_address(dev, load_address);
    wcount = 0;
    while (1) {
        memset(buf, 0, 4);
        rcount = read(fd, buf, 4);
        if (rcount >= 0) { 
            if (rcount > 0) {
                write_data(dev, buf);
                wcount += 4;
            } if (rcount < 4)
                break;          /* EOF DONE */
        } else {
           errx(1, "Error reading from %s\n", code_fname); 
        }
    }

    memset(buf, 0, 4);
    while ((wcount % 32) != 0) {
        write_data(dev, buf);
        wcount += 4;
    }

    warnx("LOAD DONE");
    set_address(dev, jmp_address);
    warnx("JMP ADDRESS SET");
    initiate_jmp(dev, jmp_address);
    warnx("JMP INITIATED");


    return 0;
}
    