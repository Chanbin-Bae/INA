#ifndef _HEADERS_
#define _HEADERS_

#include "define.p4"

#define MAX_ENTRIES_PER_PACKET 32

// typedef bit<32> ipv4_addr_t;
// typedef bit<48> mac_addr_t;
typedef bit<8> ip_protocol_t;

//------------------------------------------------------------------------------
// COMMON HEADER DEFINITIONS
//------------------------------------------------------------------------------

header ethernet_t {
    mac_addr_t dstAddr;
    mac_addr_t srcAddr;
    bit<16>    etherType;
}

header ipv4_t {
    bit<4>        version;
    bit<4>        ihl;
    bit<6>        dscp;
    bit<2>        ecn;
    bit<16>       totalLen;
    bit<16>       identification;
    bit<3>        flags;
    bit<13>       fragOffset;
    bit<8>        ttl;
    ip_protocol_t protocol;
    bit<16>       hdr_checksum;
    ipv4_addr_t   srcAddr;
    ipv4_addr_t   dstAddr;
}

header udp_t {
    bit<16>     srcPort;
    bit<16>     dstPort;
    bit<16>     length_;
    bit<16>     checksum;
}

//------------------------------------------------------------------------------
// CEINA HEADER DEFINITIONS
//------------------------------------------------------------------------------

header p4ml_t { // 10B or 11B (CEINA)
    bit<32>     bitmap;
    bit<8>      agtr_time;
    bit<1>      overflow;
    bit<2>      PSIndex;
    bit<1>      dataIndex;
    bit<1>      ECN;
    bit<1>      isResend;
    bit<1>      isWCollision;  
    bit<1>      isACK;
    bit<32>     appIDandSeqNum;
    bit<6>      padding;
    bit<2>      quantization_level; // 1 if 1bit, 2 if 32bit
}



header p4ml_agtr_index_t {
    bit<16>     agtr;
}


header bg_p4ml_t {
    bit<64>     key;     
    bit<32>     len_tensor;     
    bit<32>     bitmap;   
    bit<8>      agtr_time;   
    bit<4>      reserved;      
    bit<1>      ECN;  
    bit<1>      isResend;  
    bit<1>      isSWCollision;  
    bit<1>      isACK;  
    bit<16>     agtr; 
    bit<32>     appIDandSeqNum; 
}

header entry_t {
    bit<32>     data0 ;      
    bit<32>     data1 ;      
    bit<32>     data2 ;      
    bit<32>     data3 ;      
    bit<32>     data4 ;      
    bit<32>     data5 ;      
    bit<32>     data6 ;      
    bit<32>     data7 ;      
    bit<32>     data8 ;      
    bit<32>     data9 ;      
    bit<32>     data10;      
    bit<32>     data11;      
    bit<32>     data12;      
    bit<32>     data13;      
    bit<32>     data14;      
    bit<32>     data15;      
    bit<32>     data16;      
    bit<32>     data17;      
    bit<32>     data18;      
    bit<32>     data19;      
    bit<32>     data20;      
    bit<32>     data21;      
    bit<32>     data22;      
    bit<32>     data23;      
    bit<32>     data24;      
    bit<32>     data25;      
    bit<32>     data26;      
    bit<32>     data27;      
    bit<32>     data28;      
    bit<32>     data29;      
    bit<32>     data30;   
    bit<32>     data31;
}


header p4ml_meta_t { // 
    bit<32>     bitmap                   ; // 4B
    bit<16>     isMyAppIDandMyCurrentSeq ; // 2B
    bit<32>     isAggregate              ; // 4B // 10
    bit<8>      agtr_time                ; // 1B 
    bit<32>     integrated_bitmap        ; // 4B
    bit<8>      current_agtr_time        ; // 1B 
    bit<32>     agtr_index 	          	 ; // 4B // 20
    bit<32>     isDrop                   ; // 4B
    bit<1>      inside_appID_and_Seq     ; //   
    bit<1>      value_one                ; //  
    bit<1>      preemption               ; // 1B ///
    bit<5>      padding                  ; // 1B
    bit<8>      agtr_complete            ; // 1B // 26B
    bit<16>     qdepth                   ; // 2B  
    bit<8>      seen_bitmap0		     ; // 1B
    bit<8>      seen_isAggregate 	     ; // 1B
    bit<32>     is_ecn                   ; // 4B // 34B
    bit<8>      isAlreadyCleared         ;

}

header p4ml_constant_t {
    bit<32>     bitmap;
    bit<8>      agtr_time;
}

header entry_1bit_t {
    bit<8>      data0_1bit;
    bit<8>      data1_1bit;
    bit<8>      data2_1bit;
    bit<8>      data3_1bit;
    bit<8>      data4_1bit;
    bit<8>      data5_1bit;
    bit<8>      data6_1bit;
    bit<8>      data7_1bit;
    bit<8>      data8_1bit;
    bit<8>      data9_1bit;
    bit<8>      data10_1bit;
    bit<8>      data11_1bit;
    bit<8>      data12_1bit;
    bit<8>      data13_1bit;
    bit<8>      data14_1bit;
    bit<8>      data15_1bit;
    bit<8>      data16_1bit;
    bit<8>      data17_1bit;
    bit<8>      data18_1bit;
    bit<8>      data19_1bit;
    bit<8>      data20_1bit;
    bit<8>      data21_1bit;
    bit<8>      data22_1bit;
    bit<8>      data23_1bit;
    bit<8>      data24_1bit;
    bit<8>      data25_1bit;
    bit<8>      data26_1bit;
    bit<8>      data27_1bit;
    bit<8>      data28_1bit;
    bit<8>      data29_1bit;
    bit<8>      data30_1bit;
    bit<8>      data31_1bit;
}


//------------------------------------------------------------------------------
// UP4 HEADER DEFINITIONS
//------------------------------------------------------------------------------

header tcp_t {
    l4_port_t   sport;
    l4_port_t   dport;
    bit<32>     seq_no;
    bit<32>     ack_no;
    bit<4>      data_offset;
    bit<3>      res;
    bit<3>      ecn;
    bit<6>      ctrl;
    bit<16>     window;
    bit<16>     checksum;
    bit<16>     urgent_ptr;
}

header icmp_t {
    bit<8> icmp_type;
    bit<8> icmp_code;
    bit<16> checksum;
    bit<16> identifier;
    bit<16> sequence_number;
    bit<64> timestamp;
}

header gtpu_t {
    bit<3>  version;    /* version */
    bit<1>  pt;         /* protocol type */
    bit<1>  spare;      /* reserved */
    bit<1>  ex_flag;    /* next extension hdr present? */
    bit<1>  seq_flag;   /* sequence no. */
    bit<1>  npdu_flag;  /* n-pdn number present ? */
    bit<8>  msgtype;    /* message type */
    bit<16> msglen;     /* message length */
    teid_t  teid;       /* tunnel endpoint id */
}

// Follows gtpu_t if any of ex_flag, seq_flag, or npdu_flag is 1.
header gtpu_options_t {
    bit<16> seq_num;   /* Sequence number */
    bit<8>  n_pdu_num; /* N-PDU number */
    bit<8>  next_ext;  /* Next extension header */
}

// GTPU extension: PDU Session Container (PSC) -- 3GPP TS 38.415 version 15.2.0
// https://www.etsi.org/deliver/etsi_ts/138400_138499/138415/15.02.00_60/ts_138415v150200p.pdf
header gtpu_ext_psc_t {
    bit<8> len;      /* Length in 4-octet units (common to all extensions) */
    bit<4> type;     /* Uplink or downlink */
    bit<4> spare0;   /* Reserved */
    bit<1> ppp;      /* Paging Policy Presence (UL only, not supported) */
    bit<1> rqi;      /* Reflective QoS Indicator (UL only) */
    bit<6> qfi;      /* QoS Flow Identifier */
    bit<8> next_ext;
}

@controller_header("packet_out")
header packet_out_t {
    bit<8> reserved; // Not used
}

@controller_header("packet_in")
header packet_in_t {
    bit<32>  ingress_port;
    bit<7>      _pad;
}

//------------------------------------------------------------------------------
// HEADER STRUCTURE
//------------------------------------------------------------------------------

struct header_t {
    ethernet_t          ethernet;
    ipv4_t              ipv4;  // for mobile network
    udp_t               udp;
    //--------------------------------------------------------------------------
    // for up4
    //--------------------------------------------------------------------------
    tcp_t               tcp;
    icmp_t              icmp;
    gtpu_t              gtpu;
    gtpu_options_t      gtpu_options;
    gtpu_ext_psc_t      gtpu_ext_psc;
    ipv4_t              inner_ipv4;
    udp_t               inner_udp;
    tcp_t               inner_tcp;
    icmp_t              inner_icmp;
    //--------------------------------------------------------------------------
    // for up4
    //--------------------------------------------------------------------------
    p4ml_t              p4ml;                       // 10B                       
    p4ml_agtr_index_t   p4ml_agtr_index_useless2;   // 2B
    p4ml_agtr_index_t   p4ml_agtr_index;            // 2B
    p4ml_agtr_index_t   p4ml_agtr_index_useless;    // 2B
    entry_t             p4ml_entries_useless;       // 128B
    entry_t             p4ml_entries;               // 128B

}

//------------------------------------------------------------------------------
// CEINA METADATA DEFINITIONS
//------------------------------------------------------------------------------

header value_pair_t{
    bit<32> quantization_level;
    bit<32> appID_and_Seq;
}

//------------------------------------------------------------------------------
// UP4 METADATA DEFINITIONS
//------------------------------------------------------------------------------

struct ddn_digest_t {
    ipv4_addr_t  ue_address;
}

//------------------------------------------------------------------------------
// TOTAL METADATA DEFINITIONS
//------------------------------------------------------------------------------

struct metadata_t{

    //------------------------------------------------------------------------------
    // CEINA METADATA DEFINITIONS
    //------------------------------------------------------------------------------

    p4ml_meta_t  mdata;
    value_pair_t value_pair;

    //------------------------------------------------------------------------------
    // UP4 METADATA DEFINITIONS
    //------------------------------------------------------------------------------

    Direction direction;

    teid_t teid;

    slice_id_t slice_id;
    tc_t tc;

    ipv4_addr_t next_hop_ip;

    ipv4_addr_t ue_addr;
    ipv4_addr_t inet_addr;
    l4_port_t   ue_l4_port;
    l4_port_t   inet_l4_port;

    l4_port_t   l4_sport;
    l4_port_t   l4_dport;

    ip_proto_t  ip_proto;

    bit<8>  application_id;

    bit<8> src_iface;
    bool needs_gtpu_decap;
    bool needs_tunneling;
    bool needs_buffering;
    bool needs_dropping;
    bool terminations_hit;

    counter_index_t ctr_idx;

    tunnel_peer_id_t tunnel_peer_id;

    // GTP tunnel out parameters
    ipv4_addr_t tunnel_out_src_ipv4_addr;
    ipv4_addr_t tunnel_out_dst_ipv4_addr;
    l4_port_t   tunnel_out_udp_sport;
    teid_t      tunnel_out_teid;
    qfi_t       tunnel_out_qfi;

    session_meter_idx_t session_meter_idx_internal;
    app_meter_idx_t app_meter_idx_internal;
    MeterColor session_color;
    MeterColor app_color;
    MeterColor slice_tc_color;

    @field_list(0)
    bit<32> preserved_ingress_port;
}

#endif
