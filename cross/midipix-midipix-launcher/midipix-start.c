#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>

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
        printf("  pid: %d\n", getpid());
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

    {
        printf("testing fork...\n");
        pid_t pid = fork();
        if (pid == 0)
        {
            // Child process.
            printf("hello from the child (pid %d)\n", getpid());
            return 0;
        }
        else if (pid < 0)
        {
            perror("fork");
        }
        else
        {
            printf("waiting for child (%d)...\n", pid);
            int stat_loc = 0;
            int options = 0;
            pid_t result = waitpid(pid, &stat_loc, options);
            printf("waitpid results: ret=%d, stat_loc=%d\n", result, stat_loc);
        }
    }

    execl("bash", "bash", "--login", "-i", NULL);
    perror("execl");
    return 1;
}
