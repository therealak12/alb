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

#define MAX_TARGETS 16

struct config
{
    unsigned char client_mac[ETH_ALEN];
    unsigned int client_ip;

    unsigned char lb_mac[ETH_ALEN];
    unsigned int lb_ip;

    unsigned int backend_count;
    unsigned int backend_ips[MAX_TARGETS];
    unsigned char backend_macs[MAX_TARGETS][ETH_ALEN];
};

struct
{
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32); // simple index
    __type(value, struct config);
} settings SEC(".maps");

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

    // read settings from map
    __u32 settings_key = 0;
    struct config *cfg = bpf_map_lookup_elem(&settings, &settings_key);
    if (!cfg)
    {
        return XDP_PASS;
    }

    __u32 targetIdx = bpf_get_prandom_u32() % cfg->backend_count;
    // todo: Understand what I did here. BPF verifier seems to be too lenient! (I didn't check backend_macs)
    if (targetIdx > sizeof(cfg->backend_ips)/sizeof(cfg->backend_ips[0])) {
        return XDP_PASS;
    }
    bpf_printk("ip %d", cfg->backend_ips[targetIdx]);
    bpf_printk("mac %s", cfg->backend_macs[targetIdx]);

    if (iph->saddr == cfg->client_ip)
    {
        iph->daddr = (unsigned int)(172 + (16 << 8) + (11 << 16) + (2 << 24));
        // ns1 dev: d2:75:0b:1e:dd:c9
        // using the following line works, but the packet is delivered on both namespaces and the R. packet is not sent :|
        // memcpy(ethh->h_dest, "5e21c6e0fb0a", ETH_ALEN);
        ethh->h_dest[0] = 0xd2;
        ethh->h_dest[1] = 0x75;
        ethh->h_dest[2] = 0x0b;
        ethh->h_dest[3] = 0x1e;
        ethh->h_dest[4] = 0xdd;
        ethh->h_dest[5] = 0xc9;

        // alb host dev e2:24:03:b0:f0:d3
        ethh->h_dest[0] = 0xe2;
        ethh->h_dest[1] = 0x24;
        ethh->h_dest[2] = 0x03;
        ethh->h_dest[3] = 0xb0;
        ethh->h_dest[4] = 0xf0;
        ethh->h_dest[5] = 0xd3;
    }
    else
    {
        // client internal ip
        iph->daddr = cfg->client_ip;
        // client dev: 92:99:07:b4:30:f9
        ethh->h_dest[0] = 0x92;
        ethh->h_dest[1] = 0x99;
        ethh->h_dest[2] = 0x07;
        ethh->h_dest[3] = 0xb4;
        ethh->h_dest[4] = 0x30;
        ethh->h_dest[5] = 0xf9;
    }

    iph->saddr = cfg->lb_ip;
    // alb ns dev: d6:47:af:2c:d9:01
    ethh->h_source[0] = 0xd6;
    ethh->h_source[1] = 0x47;
    ethh->h_source[2] = 0xaf;
    ethh->h_source[3] = 0x2c;
    ethh->h_source[4] = 0xd9;
    ethh->h_source[5] = 0x01;

    iph->check = iph_csum(iph);

    return XDP_TX;
}

char _license[4] SEC("license") = "GPL";
