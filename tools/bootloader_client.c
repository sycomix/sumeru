#include <stdio.h>
#include <unistd.h>
#include <err.h>
#include <string.h>
#include <fcntl.h>

char *code_fname = "a.out";
char *dev_fname = "/dev/ttyUSB0";
unsigned char *load_address = (unsigned char *)0x10000;
unsigned char *jmp_address = (unsigned char *)0x10000;


void
process_cmdline_args(int argc, char **argv)
{
    while (1) {
        switch (getopt(argc, argv, "f:d:a:j:")) {
            case 'f':
                strcpy(code_fname, optarg);
                break;
            case 'd':
                strcpy(dev_fname, optarg);
                break;
            case 'a':
                strcpy(load_address, optarg);
                break;
            case 'j':
                strcpy(jmp_address, optarg);
                break;
            case -1:
                return;
            default:
                errx(1, "Usage: %s [-f bootcode] [-d device] "
                        "[-l load_address] [-j jmp_address]", argv[0]);
        }
    }
}


int
main(int argc, char **argv)
{
    process_cmdline_args(argc, argv);
    int fd, dev;

    if ( (fd = open(code_fname, O_RDONLY, 0)) < 0) {
        errx(1, "Error opening: %s", code_fname);
    }
    if ( (dev = open(dev_fname, O_RDWR, 0) < 0)) {
        errx(1, "Error opening: %s", dev_fname);
    }
    return 0;
}
    
