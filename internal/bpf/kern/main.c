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

struct
{
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, MAX_MAP_TARGETS);
    __type(key, __u32);   // simple index
    __type(value, __u32); // IPv4
} alb_targets SEC(".maps");

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

    // __u32 testValue = (unsigned int)(172 + (16 << 8) + (21 << 16) + (2 << 24));;
    // __u32 key = 5;
    // bpf_map_update_elem(&alb_targets, &key, &testValue, BPF_ANY);

    // __u32 targetIdx;
    // // todo: find a better solution than retrying
    // while (1)
    // {
    //     // todo: a safer solution for generating random numbers :-?
    //     // targetIdx = bpf_get_prandom_u32() % MAX_MAP_TARGETS;
    //     targetIdx = 5;
    //     bpf_printk("random %i", targetIdx);
    //     __u32 *targetIP = bpf_map_lookup_elem(&alb_targets, &targetIdx);
    //     if (!targetIP)
    //     {
    //         return XDP_PASS;
    //     }

    //     bpf_printk("%i\n\n", *targetIP);
    //     break;
    // }

    bpf_printk("%d", iph->saddr);

    if (iph->saddr == (unsigned int)(172 + (16 << 8) + (22 << 16) + (2 << 24)))
    {
        iph->daddr = (unsigned int)(172 + (16 << 8) + (21 << 16) + (2 << 24));
        // ns1 device mac address: 5e:21:c6:e0:fb:0a
        // using the following line works, but the packet is delivered on both namespaces and the R. packet is not sent :|
        // memcpy(ethh->h_dest, "5e21c6e0fb0a", ETH_ALEN);
        ethh->h_dest[0] = 0x5e;
        ethh->h_dest[1] = 0x21;
        ethh->h_dest[2] = 0xc6;
        ethh->h_dest[3] = 0xe0;
        ethh->h_dest[4] = 0xfb;
        ethh->h_dest[5] = 0x0a;
    } else {
        iph->daddr = (unsigned int)(172 + (16 << 8) + (22 << 16) + (2 << 24));
        // ns2 dev: 6a:0b:3c:00:1d:99
        ethh->h_dest[0] = 0x6a;
        ethh->h_dest[1] = 0x0b;
        ethh->h_dest[2] = 0x3c;
        ethh->h_dest[3] = 0x00;
        ethh->h_dest[4] = 0x1d;
        ethh->h_dest[5] = 0x99;
    }

    iph->saddr = (unsigned int)(172 + (16 << 8) + (11 << 16) + (2 << 24));
    // 82:fa:5d:77:a6:a9
    ethh->h_source[0] = 0x82;
    ethh->h_source[1] = 0xfa;
    ethh->h_source[2] = 0x5d;
    ethh->h_source[3] = 0x77;
    ethh->h_source[4] = 0xa6;
    ethh->h_source[5] = 0xa9;

    iph->check = iph_csum(iph);

    return XDP_TX;
}

char _license[4] SEC("license") = "GPL";
