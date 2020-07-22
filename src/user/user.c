#include <linux/bpf.h>
#include "libbpf.h"
#include "exec.skel.h"
#include <unistd.h>

int main(int ac, char **argv)
{       
        struct exec *skel = NULL;

	skel = exec__open_and_load();
	exec__attach(skel);

	sleep(1000);
	return 0;
}
