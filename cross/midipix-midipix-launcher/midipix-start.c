#include <stdio.h>
#include <unistd.h>

int main()
{
    printf("midipix-start started\n");
    execl("bash", "bash", "--login", "-i", NULL);
    perror("execl");
    return 1;
}
