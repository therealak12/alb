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

    if (iph->saddr == cfg->client_ip)
    {
        __u32 targetIdx = bpf_get_prandom_u32() % cfg->backend_count;
        // selected backend
        // todo: Understand what I did here. Why the same check is not required for backend_macs ?
        // (Learn more about how BPF verifier works)
        if (targetIdx > sizeof(cfg->backend_ips) / sizeof(cfg->backend_ips[0]))
        {
            return XDP_PASS;
        }
        iph->daddr = cfg->backend_ips[targetIdx];

        if (sizeof(cfg->backend_macs[targetIdx]) / sizeof(unsigned char) < ETH_ALEN) {
            bpf_printk("%d", sizeof(cfg->backend_macs[targetIdx]) / sizeof(unsigned char));
            return XDP_PASS;
        }

        memcpy(ethh->h_dest, cfg->backend_macs[targetIdx], ETH_ALEN);
        // bpf_printk("%x", cfg->backend_macs[targetIdx][0]);
    }
    else
    {
        // client
        iph->daddr = cfg->client_ip;
        memcpy(ethh->h_dest, cfg->client_mac, ETH_ALEN);
    }

    // alb
    iph->saddr = cfg->lb_ip;
    memcpy(ethh->h_source, cfg->lb_mac, ETH_ALEN);

    iph->check = iph_csum(iph);

    return XDP_TX;
}

char _license[4] SEC("license") = "GPL";
