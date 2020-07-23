#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

int bprm_count = 0;
int monitored_pid = 0;

SEC("lsm/bprm_committed_creds")
int BPF_PROG(test_void_hook, struct linux_binprm *bprm)
{
	char str[] = "hello\n";
	bpf_trace_printk(str, sizeof(str));
	
	//__u32 pid = bpf_get_current_pid_tgid() >> 32; 
	//if (monitored_pid == pid)
	bprm_count++;
		
	return 0;
}

char _license[] SEC("license") = "GPL";
