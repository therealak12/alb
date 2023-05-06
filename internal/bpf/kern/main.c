// go:build ignore

#include <stddef.h>
#include <arpa/inet.h>
#include <linux/bpf.h>
#include <linux/in.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <bpf_helpers.h>
#include <bpf_endian.h>

#include "utils.h"

struct hdr_container
{
    void *pos;
};

#define MAX_MAP_TARGETS 16

//struct
//{
//    __uint(type, BPF_MAP_TYPE_ARRAY);
//    __uint(max_entries, MAX_MAP_TARGETS);
//    __type(key, __u32);   // simple index
//    __type(value, __u32); // IPv4
//} alb_targets SEC(".maps");

SEC("xdp")
int alb(struct xdp_md *ctx)
{
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;

    // Track next header position in a container
    struct hdr_container nexth;

    struct ethhdr *ethh = data;
    nexth.pos = data + sizeof(struct ethhdr);
    if (nexth.pos > data_end)
    {
        return XDP_DROP;
    }

    // ALB supports ipv4 only
    if (bpf_ntohs(ethh->h_proto) != ETH_P_IP)
    {
        return XDP_PASS;
    }

    struct iphdr *iph = nexth.pos;
    nexth.pos += sizeof(struct iphdr);
    if (nexth.pos > data_end)
    {
        return XDP_DROP;
    }

    // ALB supportc TCP only
    if (iph->protocol != IPPROTO_TCP)
        return XDP_PASS;

    // ALB doesn't support IP header options
    if (iph->ihl != 5)
    {
        return XDP_PASS;
    }

    // __u32 testValue = 5;
    // bpf_map_update_elem(&alb_targets, &key, &testValue, BPF_ANY);

    // __u32 targetIdx;
    // todo: find a better way than retrying
    // while (1)
    // {
    //     // todo: a safer solution for generating random numbers :-?
    //     targetIdx = bpf_get_prandom_u32() % MAX_MAP_TARGETS;
    //     bpf_printk("random %i", targetIdx);
    //     __u32 *targetIP = bpf_map_lookup_elem(&alb_targets, &targetIdx);
    //     if (!targetIP)
    //     {
    //         return XDP_PASS;
    //     }

    //     bpf_printk("%i", *targetIP);
    //     bpf_printk("\n\n");
    //     break;
    // }

    bpf_printk("IP source %x", iph->saddr);
    bpf_printk("IP destination %x", iph->daddr);

    // e2:24:03:b0:f0:d3
    // h_source = alb ns interface
    // ethh->h_source[0] = 0xe2;
    // ethh->h_source[1] = 0x24;
    // ethh->h_source[2] = 0x03;
    // ethh->h_source[3] = 0xb0;
    // ethh->h_source[4] = 0xf0;
    // ethh->h_source[5] = 0xd3;

#define BACKEND_A 2
#define BACKEND_B 3
#define CLIENT 4
#define LB 5

#define IP_ADDRESS(x) (unsigned int)(172 + (17 << 8) + (0 << 16) + (x << 24))

    char backend = BACKEND_A;

    // iph->daddr = (unsigned int)(172 + (17 << 8) + (0 << 16) + (backend << 24));
    iph->daddr = IP_ADDRESS(backend);
    ethh->h_dest[5] = backend;

    iph->check = iph_csum(iph);

    return XDP_TX;
}

char _license[4] SEC("license") = "GPL";
