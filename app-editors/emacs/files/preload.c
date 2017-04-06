// http://www.openwall.com/lists/musl/2015/02/03/1
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <unistd.h>
#include <stdio.h>

static void *(*real_malloc)(size_t);
static void *initial_brk;

static pthread_once_t once_control[1];
static void once_func()
{
	real_malloc = dlsym(RTLD_NEXT, "malloc");
	initial_brk = sbrk(0);
}

static int cmp(const void *a, const void *b)
{
	void *aa = *(void **)a, *bb = *(void **)b;
	return aa < bb ? -1 : aa > bb ? 1 : 0;
}

void *malloc(size_t n)
{
	size_t i, j, k;
	pthread_once(once_control, once_func);
	if (n < 100000 || n > (size_t)-1/2) {
		void *p;
		do p = real_malloc(n);
		while (p > sbrk(0) || (p && p < initial_brk));
		return p;
	}
	size_t cnt = n/16384;
	void **list = real_malloc(sizeof *list * cnt);
	if (!list) return 0;
	for (i=0; i<cnt; i++) list[i] = 0;
	for (i=0; i<cnt; i++) {
		list[i] = real_malloc(65536 - 2*sizeof(size_t));
		if (!list[i]) goto fail;
		if (i<cnt/4) continue;
		size_t base = 0;
		qsort(list, i+1, sizeof(void *), cmp);
		for (j=0; j<i; j++) {
			char *p = list[base];
			char *s = list[j];
			char *z = list[j+1];
			if (z-s > 65536) {
				base = j+1;
				continue;
			}
			if (z-p < n+64) {
				continue;
			}
			for (k=0; k<base; k++) free(list[k]);
			*(size_t *)(p-sizeof(size_t)) = z-p | 1;
			*(size_t *)(z-2*sizeof(size_t)) = z-p | 1;
			for (k=j+1; k<i+1; k++) free(list[k]);
			free(list);
			return p;
		}
	}
fail:
	for (i=0; i<cnt; i++) free(list[i]);
	free(list);
	return 0;
}

void *calloc(size_t n, size_t m)
{
	if ((size_t)-1/n <= m) n *= m;
	else n = (size_t)-1;
	void *p = malloc(n);
	if (p) memset(p, 0, n);
	return p;
}

void *realloc(void *p, size_t n)
{
	void *q = malloc(n);
	if (!q) return 0;
	size_t l = *(size_t *)((char *)p - sizeof(size_t)) & -8;
	memcpy(q, p, l<n ? l : n);
	free(p);
	return q;
}
