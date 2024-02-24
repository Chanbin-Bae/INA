#ifndef _PARSERS_
#define _PARSERS_

#include "headers.p4"

#define PKT_INSTANCE_TYPE_RESUBMIT 6
#define PKT_INSTANCE_TYPE_RECIRC 4


parser NativeUP4Parser(
    packet_in pkt,
    out header_t hdr,
    inout metadata_t md,
    inout standard_metadata_t standard_metadata) {

    state start {
            //transition select(standard_metadata.ingress_port)
            // CPU_PORT: parse_packet_out;
            transition parse_ethernet;
    }

    // state parse_packet_out {
    //     pkt.extract(hdr.packet_out);
    //     transition parse_ethernet;
    // }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800 : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IpProtocol.UDP:  parse_udp;
            IpProtocol.TCP:  parse_tcp;
            IpProtocol.ICMP: parse_icmp;
            IpProtocol.P4ML: parse_p4ml;
            default: accept;
        }
    }

        state parse_udp {
        pkt.extract(hdr.udp);
        // note: this eventually wont work
        md.l4_sport = hdr.udp.srcPort;
        md.l4_dport = hdr.udp.dstPort;
        gtpu_t gtpu = pkt.lookahead<gtpu_t>();
        transition select(hdr.udp.dstPort, gtpu.version, gtpu.msgtype) {
            (L4Port.IPV4_IN_UDP, _, _): parse_inner_ipv4;
            // Treat GTP control traffic as payload.
            (L4Port.GTP_GPDU, GTP_V1, GTPUMessageType.GPDU): parse_gtpu;
            default: accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        md.l4_sport = hdr.tcp.sport;
        md.l4_dport = hdr.tcp.dport;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_gtpu {
        pkt.extract(hdr.gtpu);
        md.teid = hdr.gtpu.teid;
        transition select(hdr.gtpu.ex_flag, hdr.gtpu.seq_flag, hdr.gtpu.npdu_flag) {
            (0, 0, 0): parse_inner_ipv4;
            default: parse_gtpu_options;
        }
    }

    state parse_gtpu_options {
        pkt.extract(hdr.gtpu_options);
        bit<8> gtpu_ext_len = pkt.lookahead<bit<8>>();
        transition select(hdr.gtpu_options.next_ext, gtpu_ext_len) {
            (GTPU_NEXT_EXT_PSC, GTPU_EXT_PSC_LEN): parse_gtpu_ext_psc;
            default: accept;
        }
    }

    state parse_gtpu_ext_psc {
        pkt.extract(hdr.gtpu_ext_psc);
        transition select(hdr.gtpu_ext_psc.next_ext) {
            GTPU_NEXT_EXT_NONE: parse_inner_ipv4;
            default: accept;
        }
    }

    //-----------------
    // Inner packet: real dst,src addr
    //-----------------

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            IpProtocol.UDP:  parse_inner_udp;
            IpProtocol.TCP:  parse_inner_tcp;
            IpProtocol.ICMP: parse_inner_icmp;
            IpProtocol.P4ML: parse_p4ml;
            default: accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        md.l4_sport = hdr.inner_udp.srcPort;
        md.l4_dport = hdr.inner_udp.dstPort;
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        md.l4_sport = hdr.inner_tcp.sport;
        md.l4_dport = hdr.inner_tcp.dport;
        transition accept;
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }


    state parse_p4ml {
        pkt.extract(hdr.p4ml);
        transition select(hdr.p4ml.dataIndex) {
            0x0     : use_first_p4ml_agtr_index_recirculate;
            0x1     : use_second_p4ml_agtr_index_recirculate;
            default : accept;
        }
    }


    state parse_entry {
        pkt.extract(hdr.p4ml_entries);
        md.mdata.setValid(); ///
        transition accept;
    }

// Recirculation 1
    state use_first_p4ml_agtr_index_recirculate {
        pkt.extract(hdr.p4ml_agtr_index);
        // [I]
        transition useless_second_p4ml_agtr_index_recirculate;
    } 


    state useless_second_p4ml_agtr_index_recirculate {
        pkt.extract(hdr.p4ml_agtr_index_useless); 
        transition parse_entry; 
    }   // [I][I_useless][E]

// Recirculation 2
    state use_second_p4ml_agtr_index_recirculate {
        pkt.extract(hdr.p4ml_agtr_index_useless2); 
        transition parse_p4ml_agtr_index_recirculate;
    }   // [I_useless2]

    state parse_p4ml_agtr_index_recirculate {
        pkt.extract(hdr.p4ml_agtr_index); 
        transition select(hdr.p4ml.quantization_level){
          0x2   : parse_entry2;       // [I_useless2][I][(128B)E_useless][(128B)E]
    //       0x1   : parse_entry2_1bit;  // [I_useless2][I][(32B)E_useless ][(128B)E]
          default : accept;
        }
    }   // [I_useless2][I]

    state parse_entry2 {
        pkt.extract(hdr.p4ml_entries_useless); 
        transition parse_entry; 
    }   // [I_useless2][I][(128B)E_useless][(128B)E]

    // state parse_entry2_1bit {
    //     pkt.extract(hdr.p4ml_entries_1bit_useless2); 
    //     transition parse_entry; 
    // }   // [I_useless2][I][(32B)E_useless ][(128B)E]

    } //parser

control NativeUP4Deparser(packet_out pkt, in header_t hdr) {
        apply{
            pkt.emit(hdr);

        }
}

#endif 

// control DeparserImpl(packet_out pkt, in header_t hdr) {
//         apply{
//             pkt.emit(hdr.packet_in);
//             pkt.emit(hdr.ethernet);
//             pkt.emit(hdr.ipv4);
//             pkt.emit(hdr.udp);
//             pkt.emit(hdr.tcp);
//             pkt.emit(hdr.icmp);
//             pkt.emit(hdr.gtpu);
//             pkt.emit(hdr.gtpu_options);
//             pkt.emit(hdr.gtpu_ext_psc);
//             pkt.emit(hdr.inner_ipv4);
//             pkt.emit(hdr.inner_udp);
//             pkt.emit(hdr.inner_tcp);
//             pkt.emit(hdr.inner_icmp);
//             pkt.emit(hdr.p4ml);
//             pkt.emit(hdr.p4ml_entries);
//             pkt.emit(hdr.p4ml_agtr_index);
//             pkt.emit(hdr.p4ml_agtr_index_useless);
//             pkt.emit(hdr.p4ml_agtr_index_useless2);
//             pkt.emit(hdr.p4ml_agtr_index);
// 
//         }
// }
