#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/printk.h>
#include <linux/proc_fs.h>
#include <linux/uaccess.h>
#include <linux/version.h>
#include <linux/ktime.h>
#include <linux/time.h>
#include <linux/string.h>

#define procfs_name "tsulab"
static struct proc_dir_entry *our_proc_file = NULL;

static int get_days(void) {
	struct timespec64 ts_now;
	time64_t seconds_impact, seconds_now;
	s64 seconds_diff;

	seconds_impact = mktime64(1994, 7, 16, 0, 0, 0);

	ktime_get_real_ts64(&ts_now);
	seconds_now = ts_now.tv_sec;

	seconds_diff = seconds_now - seconds_impact;

	return (int)(seconds_diff / (60*60*24));
}

static ssize_t procfile_read(struct file *file_pointer, char __user *buffer, size_t buffer_length, loff_t* offset) {
	int days = get_days();
	char s[20];

	int len = snprintf(s, sizeof(s) - 2, "%d", days);
	s[len] = '\n';
	s[len + 1] = '\0';

	if (*offset >= len + 2) {
		return 0;
	}

	copy_to_user(buffer, s + *offset, len + 2);
	*offset += len + 2;

	pr_info("procfile read %s\n", file_pointer->f_path.dentry->d_name.name);
	return len + 2;
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 6, 0)
static const struct proc_ops proc_file_fops = {
	.proc_read = procfile_read,
};
#else
static const struct file_operations proc_file_fops = {
	.read = procfile_read,
};
#endif

static int __init tsu_init(void) {
	pr_info("Welcome to the Tomsk State University\n");
	our_proc_file = proc_create(procfs_name, 0644, NULL, &proc_file_fops);
	return 0;
}

static void __exit tsu_cleanup(void) {
	proc_remove(our_proc_file);
	pr_info("/proc/%s removed\n", procfs_name);
	pr_info("Tomsk State University forever!\n");
}

module_init(tsu_init);
module_exit(tsu_cleanup);
MODULE_LICENSE("GPL");
