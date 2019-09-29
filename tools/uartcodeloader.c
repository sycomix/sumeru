#include <sys/types.h>
#include <fcntl.h>
#include <err.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>

int in_fd, out_fd;

unsigned int
read_result(int *ev)
{
    unsigned int y, x;

    *ev = 0;
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
                } else
                    err(1, "Error reading result from port");
            } else if (y < 0)
                errx(1, "Error reading result from port: %d", y);
        }
        return x;
    }

    *ev = 1;
    return x;
}

void
set_address(unsigned int addr, int retry_count)
{
    unsigned int r;
    unsigned char buf[5];
    int ev;
    
    buf[0] = 'A';
    for (int i = 0; i < 4; ++i)
        buf[i + 1] = ((unsigned char*)&addr)[i];

    if (write(out_fd, &buf, 5) != 5)
        errx(1, "Error writing address to port");

    r = read_result(&ev);
    if (ev != 0 || r != addr) {
        if (retry_count <= 0) {
            errx(1, "Invalid address command result expecting 0x%x, got 0x%x", addr, r);
        } else {
            warnx("Invalid address command result expecting 0x%x, got 0x%x", addr, r);
            set_address(addr, retry_count - 1);
        }
    }
}

void
write_data(unsigned int addr, unsigned int data, int retry_count)
{
    unsigned int r;
    unsigned char buf[5];
    int ev;
    
    buf[0] = 'W';
    for (int i = 0; i < 4; ++i)
        buf[i + 1] = ((unsigned char*)&data)[i];

    if (write(out_fd, &buf, 5) != 5)
        errx(1, "Error writing data to port");

    r = read_result(&ev);
    if (ev !=0 || r != data) {
        if (retry_count <= 0) {
            errx(1, "Invalid write command result expecting 0x%x, got 0x%x", data, r);
        } else {
            warnx("Invalid write command result expecting 0x%x, got 0x%x", data, r);
            set_address(addr, retry_count - 1);
            write_data(addr, data, retry_count - 1);
        }
    }
}

void
trigger_jmp()
{
    if (write(out_fd, "JJJJJ", 5) != 5)
        errx(1, "Error writing data to port");
}


int
main(int argc, char **argv)
{
    unsigned int addr, x;
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

        write_data(addr, x, 4);
        addr += 4;
    }

    addr = 0x00010000;
    set_address(addr, 4);
    if (argc == 3) {
        warnx("Data load complete, triggering jump!");
        trigger_jmp();
    }

    return 0;
}
