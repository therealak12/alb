#include <arpa/inet.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
	if (argc < 2) {
		printf("IP address is empty");
		return 1;
	}
	uint32_t ip;
	sscanf(argv[1],"%d",&ip);
	struct in_addr ip_addr;
	ip_addr.s_addr = ip;
	printf("The IP address is %s\n", inet_ntoa(ip_addr));
}
