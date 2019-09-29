#include <sys/types.h>
#include <fcntl.h>
#include <err.h>
#include <unistd.h>

int
main(int argc, char **argv)
{
    int in_fd, out_fd, x;

    if (argc != 3)
        return 0;

    if ( (in_fd = open(argv[1], O_RDONLY)) < 0)
        errx(1, "Error opening input file: %s\n", argv[1]);

    if ( (out_fd = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0660)) < 0)
        errx(1, "Error opening output file: %s\n", argv[2]);

    write(out_fd, "A\n\x00\x01\x00\x00\n", 7);

    while (1) {
        if (read(in_fd, &x, sizeof(x)) != sizeof(x))
            break;
        write(out_fd, "W\n", 2);
        write(out_fd, &x, sizeof(x));
        write(out_fd, "\n", 1);
    }

    write(out_fd, "A\n\x00\x01\x00\x00\n", 7);
    return 0;
}
