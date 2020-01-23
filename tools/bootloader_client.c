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

void
set_address(int dev, unsigned char *address)
{
    char buf[16];

    buf[0] = 'A';
    memcpy(buf + 1, &address, 4);
    buf[5] = buf[1] ^ buf[2] ^ buf[3] ^ buf[4];
    write(dev, buf, 6);
    read(dev, buf, 1);
    if (buf[0] != 'O')
        errx(1, "Error setting address: %x", (int)buf[0]);
}


void
write_data(int dev, char *data)
{
    char buf[16];

    buf[0] = 'W';
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
    int fd, dev, rcount, pos;

    process_cmdline_args(argc, argv);

    if ( (fd = open(code_fname, O_RDONLY, 0)) < 0) {
        errx(1, "Error opening: %s", code_fname);
    }
    if ( (dev = open(dev_fname, O_RDWR, 0)) < 0) {
        errx(1, "Error opening: %s", dev_fname);
    }

    pos = 0;
    set_address(dev, load_address);
    while (1) {
        buf[0] = buf[1] = buf[2] = buf[3];
        rcount = read(fd, buf, 4);
        if (rcount >= 0) { 
            write_data(dev, buf);
            if (rcount < 4)
                break;          /* EOF DONE */
        } else {
           errx(1, "Error reading from %s\n", code_fname); 
        }
        warnx("%d ", pos);
        pos += 4;
        usleep(1000);
    }

    return 0;
}
    
