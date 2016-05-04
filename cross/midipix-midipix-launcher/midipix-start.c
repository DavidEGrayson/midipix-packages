#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>

int fd_is_valid(int fd)
{
    return fcntl(fd, F_GETFD) != -1;
}

int main()
{
    printf("midipix-start started\n");
    fprintf(stderr, "midipix-start stderr works\n");

    {
        // TODO: fix this; calling getpid seems to make this program hang
        //printf("  pid: %s\n", getpid());
    }

    {
        char cwd[512];
        char * result = getcwd(cwd, sizeof(cwd));
        if (result == NULL)
        {
            perror("getcwd");
        }
        else
        {
            printf("  getcwd: %s\n", cwd);
        }
    }

    for (int fd = 0; fd < 10; fd++)
    {
        if (fd_is_valid(fd))
        {
            printf("  isatty(%d) = %d\n", fd, isatty(fd));
        }
    }

    {
        // TODO: is chroot actually needed?  Seems like it is isn't.
        int result = chroot("//c/midipix");
        if (result != 0)
        {
            perror("chroot");
        }
    }

    execl("bash", "bash", "--login", "-i", NULL);
    perror("execl");
    return 1;
}
