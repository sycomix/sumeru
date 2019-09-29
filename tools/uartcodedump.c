#include <sys/types.h>
#include <fcntl.h>
#include <err.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>

int in_fd, out_fd;

unsigned int
read_result()
{
    unsigned int y, x;

    for (int i = 0; i < 100; ++i) {
        if ((y = read(out_fd, &x, sizeof(x))) != sizeof(x)) {
            if (y == 0) {
                if (errno == EWOULDBLOCK) {
                    errx(1, "EOF encountered while reading from port");
                }
            } else if (y == -1) {
                if (errno == EWOULDBLOCK) {
                    usleep(50);
                    continue;
                }
            } else if (y < 0)
                errx(1, "Error reading result from port: %d", y);
        }
        return x;
    }

    printf("0x%x\n", x);
    return x;
}

void
set_address(unsigned int addr, int retry_count)
{
    unsigned int r;
    unsigned char buf[5];
    
    buf[0] = 'A';
    for (int i = 0; i < 4; ++i)
        buf[i + 1] = ((unsigned char*)&addr)[i];

    if (write(out_fd, &buf, 5) != 5)
        errx(1, "Error writing address to port");

    r = read_result();
    if (r != addr) {
        if (retry_count <= 0) {
            errx(1, "Invalid address command result expecting 0x%x, got 0x%x", addr, r);
        } else {
            warnx("Invalid address command result expecting 0x%x, got 0x%x", addr, r);
            set_address(addr, retry_count - 1);
        }
    }
}

unsigned int
read_data(unsigned int addr)
{
    unsigned int r;
    unsigned char buf[5];
    
    buf[0] = 'R';
    buf[1] = 'R';
    buf[2] = 'R';
    buf[3] = 'R';
    buf[4] = 'R';

    if (write(out_fd, &buf, 5) != 5)
        errx(1, "Error writing data to port");

    r = read_result();
    return r;
}

int
main(int argc, char **argv)
{
    unsigned int addr, x, r;
    int c;

    if (argc < 3)
        return 0;

    if ( (in_fd = open(argv[1], O_RDONLY)) < 0)
        errx(1, "Error opening input file: %s\n", argv[1]);

    if ( (out_fd = open(argv[2], O_NONBLOCK | O_RDWR)) < 0)
        errx(1, "Error opening uart device: %s\n", argv[2]);

    addr = 0x00010000;
    set_address(addr, 4);

    while (1) {
        c = read(in_fd, &x, sizeof(x));
        if (c == 0)
            break;
        else if (c > 0 && c != 4)
            errx(1, "Invalid file: File size must be divisible by 4");
        else if (c < 0)
            err(1, "Error reading from file");

        r = read_data(addr);
        if (x != r) {
            warnx("Data mismatch at address 0x%x, expecting %d got %d\n", addr, x, r);
        }
        addr += 4;
    }

    addr = 0x00010000;
    set_address(addr, 4);
    return 0;
}
