#include <machine/csr.h>
#include <machine/uart0.h>
#include <stdio.h>

#define LINE_MAX        128

int
read_string(char *buf, unsigned int buf_len)
{
    int i;

    --buf_len;
    for (i = 0; i < buf_len; ++i) {
        uart0_blocking_read((unsigned char *)(buf + i), 1);
        if (buf[i] == '\n') {
            break;
        }
    }
    buf[i] = 0;
    return i;
}


int
main(int argc, char **argv, char **envp)
{
    char i, buf[LINE_MAX];

    while (1) {
        i = read_string(buf, LINE_MAX);
        printf("%d %s\n", i, buf);
    }
    return 0;
}
