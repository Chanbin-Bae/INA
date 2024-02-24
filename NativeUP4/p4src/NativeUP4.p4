#include <core.p4>
#include <v1model.p4>



#include "include/headers.p4"
#include "include/parser.p4"
#include "include/define.p4"
#include "include/checksum.p4"

//------------------------------------------------------------------------------
// ROUTING BLOCK
//------------------------------------------------------------------------------
control Routing(inout header_t    hdr,
                inout metadata_t    md,
                inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action route(mac_addr_t src_mac,
                 mac_addr_t dst_mac,
                 bit<32> egress_port) {
        standard_metadata.egress_spec = (bit<9>)egress_port;
        hdr.ethernet.srcAddr = src_mac;
        hdr.ethernet.dstAddr = dst_mac;
    }

    table routes_v4 {
        key = {
            hdr.ipv4.dstAddr      : lpm @name("dst_prefix");
            hdr.ipv4.srcAddr      : selector;
            hdr.ipv4.protocol         : selector;
            md.l4_sport    : selector;
            md.l4_dport    : selector;
        }
        actions = {
            route;
        }
        @name("hashed_selector")
        implementation = action_selector(HashAlgorithm.crc16, 32w1024, 32w16);
        size = MAX_ROUTES;
    }

    apply {
        // Normalize IP address for routing table, and decrement TTL
        // TODO: find a better alternative to this hack
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        if (hdr.ipv4.ttl == 0) {
            drop();
        }
        else {
            routes_v4.apply();
        }
    }
}


control NativeUP4Ingress(
    inout header_t hdr,
    inout metadata_t md,
    inout standard_metadata_t standard_metadata) {

//------------------------------------------------------------------------------
// INA BLOCK
//------------------------------------------------------------------------------

    bit<32> CheckForAppIDandSeq;
    bit<32> Check_for_resend;
    bit<32> Check_for_check;
    bit<32> Check_for_appID_and_Seq;
    bit<32> Check_for_aggregate;
    bit<32> Check_value;
    bit<32> index_for_register = (bit<32>)hdr.p4ml_agtr_index.agtr;
    bit<32> index_for_current_agtr_time = (bit<32>)md.mdata.current_agtr_time;
    bit<8> quantization_level_const;



    #include "include/registers.p4"
    #include "include/actions.p4"
    #include "include/tables.p4"
    #include "include/common.p4"

//------------------------------------------------------------------------------
// UP4 BLOCK
//------------------------------------------------------------------------------

    action _initialize_metadata() {
        md.session_meter_idx_internal = DEFAULT_SESSION_METER_IDX;
        md.app_meter_idx_internal = DEFAULT_APP_METER_IDX;
        md.preserved_ingress_port = (bit<32>) standard_metadata.ingress_port;
    }

    table my_station {
        key = {
            hdr.ethernet.dstAddr : exact @name("dst_mac");
        }
        actions = {
            NoAction;
        }
    }

    action set_source_iface(Direction direction) {
        // Interface type can be access, core (see InterfaceType enum)
        // If interface is from the control plane, direction can be either up or down
        md.direction = direction;
    }

    table interfaces {
        key = {
            hdr.ipv4.dstAddr : lpm @name("ipv4_dst_prefix");
        }
        actions = {
            set_source_iface;
        }
        const default_action = set_source_iface(Direction.UNKNOWN);
    }

    @hidden
    action gtpu_decap() {
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ipv4.setInvalid();
        hdr.udp = hdr.inner_udp;
        hdr.inner_udp.setInvalid();
        hdr.tcp = hdr.inner_tcp;
        hdr.inner_tcp.setInvalid();
        hdr.icmp = hdr.inner_icmp;
        hdr.inner_icmp.setInvalid();
        hdr.gtpu.setInvalid();
        hdr.gtpu_options.setInvalid();
        hdr.gtpu_ext_psc.setInvalid();
    }

    action do_drop() {
        mark_to_drop(standard_metadata);
        exit;
    }

    action set_session_uplink() {
        md.needs_gtpu_decap = true;
    }

    action set_session_uplink_drop() {
        md.needs_dropping = true;
    }

    action set_session_downlink(tunnel_peer_id_t tunnel_peer_id) {
        md.tunnel_peer_id = tunnel_peer_id;
    }
    action set_session_downlink_drop() {
        md.needs_dropping = true;
    }

    action set_session_downlink_buff() {
        md.needs_buffering = true;
    }

    table sessions_uplink {
        key = {
            hdr.ipv4.dstAddr   : exact @name("n3_address");
            md.teid     : exact @name("teid");
            // egress_port??
        }
        actions = {
            set_session_uplink;
            set_session_uplink_drop;
            @defaultonly do_drop;
        }
        const default_action = do_drop;
    }

    table sessions_downlink {
        key = {
            hdr.ipv4.dstAddr   : exact @name("ue_address");
        }
        actions = {
            set_session_downlink;
            set_session_downlink_drop;
            set_session_downlink_buff;
            @defaultonly do_drop;
        }
        const default_action = do_drop;
    }

    action uplink_term_fwd() {
    }

    action uplink_term_drop() {
        md.needs_dropping = true;
    }

    // QFI = 0 for 4G traffic
    action downlink_term_fwd(teid_t teid, qfi_t qfi) {
        md.tunnel_out_teid = teid;
        md.tunnel_out_qfi = qfi;
    }

    action downlink_term_drop() {
        md.needs_dropping = true;
    }

    table terminations_uplink {
        key = {
            md.ue_addr          : exact @name("ue_address"); // Session ID
        }
        actions = {
            uplink_term_fwd;
            uplink_term_drop;
            @defaultonly do_drop;
        }
        const default_action = do_drop;
    }

    table terminations_downlink {
        key = {
            md.ue_addr          : exact @name("ue_address"); // Session ID
        }
        actions = {
            downlink_term_fwd;
            downlink_term_drop;
            @defaultonly do_drop;
        }
        const default_action = do_drop;
    }

    action load_tunnel_param(ipv4_addr_t    src_addr,
                             ipv4_addr_t    dst_addr,
                             l4_port_t      sport
                             ) {
        md.tunnel_out_src_ipv4_addr = src_addr;
        md.tunnel_out_dst_ipv4_addr = dst_addr;
        md.tunnel_out_udp_sport     = sport;
        md.needs_tunneling          = true;
    }

    table tunnel_peers {
        key = {
            md.tunnel_peer_id : exact @name("tunnel_peer_id");
        }
        actions = {
            load_tunnel_param;
        }
    }

    @hidden
    action _udp_encap(ipv4_addr_t src_addr, ipv4_addr_t dst_addr,
                      l4_port_t udp_sport, l4_port_t udp_dport,
                      bit<16> ipv4_total_len,
                      bit<16> udp_len) {
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
        hdr.inner_icmp = hdr.icmp;
        hdr.icmp.setInvalid();
        hdr.udp.setValid();
        hdr.udp.srcPort = udp_sport;
        hdr.udp.dstPort = udp_dport;
        hdr.udp.length_ = udp_len;
        hdr.udp.checksum = 0; // Never updated due to p4 limitations

        hdr.inner_ipv4 = hdr.ipv4;
        hdr.ipv4.setValid();
        hdr.ipv4.version = IP_VERSION_4;
        hdr.ipv4.ihl = IPV4_MIN_IHL;
        hdr.ipv4.dscp = 0;
        hdr.ipv4.ecn = 0;
        hdr.ipv4.totalLen = ipv4_total_len;
        hdr.ipv4.identification = 0x1513; // TODO: change this to timestamp or some incremental num
        hdr.ipv4.flags = 0;
        hdr.ipv4.fragOffset = 0;
        hdr.ipv4.ttl = DEFAULT_IPV4_TTL;
        hdr.ipv4.protocol = IpProtocol.UDP;
        hdr.ipv4.srcAddr = src_addr;
        hdr.ipv4.dstAddr = dst_addr;
        hdr.ipv4.hdr_checksum = 0; // Updated later


    }

    @hidden
    action _gtpu_encap(teid_t teid) {
        hdr.gtpu.setValid();
        hdr.gtpu.version = GTP_V1;
        hdr.gtpu.pt = GTP_PROTOCOL_TYPE_GTP;
        hdr.gtpu.spare = 0;
        hdr.gtpu.ex_flag = 0;
        hdr.gtpu.seq_flag = 0;
        hdr.gtpu.npdu_flag = 0;
        hdr.gtpu.msgtype = GTPUMessageType.GPDU;
        hdr.gtpu.msglen = hdr.inner_ipv4.totalLen;
        hdr.gtpu.teid = teid;
    }

    action do_gtpu_tunnel() {
        _udp_encap(md.tunnel_out_src_ipv4_addr,
                   md.tunnel_out_dst_ipv4_addr,
                   md.tunnel_out_udp_sport,
                   (bit<16>)L4Port.GTP_GPDU,
                   hdr.ipv4.totalLen + IPV4_HDR_SIZE + UDP_HDR_SIZE + GTP_HDR_MIN_SIZE,
                   hdr.ipv4.totalLen + UDP_HDR_SIZE + GTP_HDR_MIN_SIZE);
        _gtpu_encap(md.tunnel_out_teid);
    }


    action do_gtpu_tunnel_with_psc() {
        _udp_encap(md.tunnel_out_src_ipv4_addr,
                   md.tunnel_out_dst_ipv4_addr,
                   md.tunnel_out_udp_sport,
                   (bit<16>)L4Port.GTP_GPDU,
                   hdr.ipv4.totalLen + IPV4_HDR_SIZE + UDP_HDR_SIZE + GTP_HDR_MIN_SIZE
                    + GTPU_OPTIONS_HDR_BYTES + GTPU_EXT_PSC_HDR_BYTES,
                   hdr.ipv4.totalLen + UDP_HDR_SIZE + GTP_HDR_MIN_SIZE
                    + GTPU_OPTIONS_HDR_BYTES + GTPU_EXT_PSC_HDR_BYTES);
        _gtpu_encap(md.tunnel_out_teid);
        hdr.gtpu.msglen = hdr.inner_ipv4.totalLen + GTPU_OPTIONS_HDR_BYTES
                            + GTPU_EXT_PSC_HDR_BYTES; // Override msglen set by _gtpu_encap
        hdr.gtpu.ex_flag = 1; // Override value set by _gtpu_encap
        hdr.gtpu_options.setValid();
        hdr.gtpu_options.seq_num   = 0;
        hdr.gtpu_options.n_pdu_num = 0;
        hdr.gtpu_options.next_ext  = GTPU_NEXT_EXT_PSC;
        hdr.gtpu_ext_psc.setValid();
        hdr.gtpu_ext_psc.len      = GTPU_EXT_PSC_LEN;
        hdr.gtpu_ext_psc.type     = GTPU_EXT_PSC_TYPE_DL;
        hdr.gtpu_ext_psc.spare0   = 0;
        hdr.gtpu_ext_psc.ppp      = 0;
        hdr.gtpu_ext_psc.rqi      = 0;
        hdr.gtpu_ext_psc.qfi      = md.tunnel_out_qfi;
        hdr.gtpu_ext_psc.next_ext = GTPU_NEXT_EXT_NONE;
    }

apply{
    _initialize_metadata();

    if ( hdr.p4ml_entries.isValid()) {
        md.mdata.setValid();

            if (hdr.ipv4.ecn == 3 || hdr.p4ml.ECN == 1) {
                setup_ecn_table.apply();
            }
            // ack packet
            if (hdr.p4ml.isACK == 1) {
                
                if (hdr.p4ml.overflow == 1 && hdr.p4ml.isResend == 0) {

                } else {
                    appID_and_Seq.read(Check_for_appID_and_Seq,index_for_register);
                    if(Check_for_appID_and_Seq == hdr.p4ml.appIDandSeqNum){
                        clean_appID_and_seq_table.apply();
                    }                    
                    
                    if (md.mdata.isMyAppIDandMyCurrentSeq != 0) {
                        /* Clean */
                        // clean_bitmap_table.apply();
                        // clean_ecn_table.apply();
                        // clean_agtr_time_table.apply();
                        // // apply(cleanEntry1);
                        
                        // do_cleanEntry1();
                        // do_cleanEntry2();
                        // do_cleanEntry3();
                        // do_cleanEntry4();
                        // do_cleanEntry5();
                        // do_cleanEntry6();
                        // do_cleanEntry7();
                        // do_cleanEntry8();
                        // do_cleanEntry9();
                        // do_cleanEntry10();
                        // do_cleanEntry11();
                        // do_cleanEntry12();
                        // do_cleanEntry13();
                        // do_cleanEntry14();
                        // do_cleanEntry15();
                        // do_cleanEntry16();
                        // do_cleanEntry17();
                        // do_cleanEntry18();
                        // do_cleanEntry19();
                        // do_cleanEntry20();
                        // do_cleanEntry21();
                        // do_cleanEntry22();
                        // do_cleanEntry23();
                        // do_cleanEntry24();
                        // do_cleanEntry25();
                        // do_cleanEntry26();
                        // do_cleanEntry27();
                        // do_cleanEntry28();
                        // do_cleanEntry29();
                        // do_cleanEntry30();
                        // do_cleanEntry31();
                        // do_cleanEntry32();
                    }
                }

                // /* Multicast Back */

                multicast_table.apply();
                
            } else {

                if (hdr.p4ml.overflow == 1) {
                    outPort_table.apply();
                } else {
                    if (hdr.p4ml.isResend == 1) {
                        appID_and_Seq_pair.read(Check_for_resend, index_for_register);
                        if(Check_for_resend == hdr.p4ml.appIDandSeqNum){
                            appID_and_seq_resend_table.apply();
                        }
                        else{
                            md.mdata.isAlreadyCleared = 1;
                        }
                        
                    } else {
                        
                        if(md.value_pair.quantization_level > 0){

                        } else{
                            appID_and_seq_table.apply();
                        }

                        appID_and_Seq_pair.read(CheckForAppIDandSeq, index_for_register);
                        md.mdata.isMyAppIDandMyCurrentSeq = (bit<16>) CheckForAppIDandSeq;
                    }
                    // Correct ID and Seq
                    if (md.mdata.isMyAppIDandMyCurrentSeq != 0){ // && ig_md.mdata.preemption == 1) {
                        
                        if (hdr.p4ml.isResend == 1) {
                            // Clean the bitmap also
                            bitmap_resend_table.apply(); //////0516 check
                        } else {
                            bitmap_table.apply();
                        }
                        ecn_register.read(Check_value, index_for_register);
                        if(Check_value == 1){
                            Check_value = Check_value | md.mdata.is_ecn;
                            ecn_register_table.apply();
                        }
                        // ecn_register_table.apply();
                        bitmap_aggregate_table.apply();

                        if (hdr.p4ml.isResend == 1) {
                            // Force forward and clean
                            agtr_time_resend_table.apply();  //////0516 check
                        } else {
                            if(md.mdata.isAggregate != 0){
                                agtr_time_table_nonzero.apply();
                            }
                            else{
                                agtr_time_table_zero.apply();
                            }
                            // agtr_time_table.apply();
                        }

                          // if(hdr.p4ml.agtr_time == ig_md.mdata.current_agtr_time){
                          //     ig_md.mdata.agtr_complete = true;
                          // }
                          // else{
                          //     ig_md.mdata.agtr_complete = false;
                          // }

                          NewprocessEntry1.apply();
                          NewprocessEntry2.apply();
                          NewprocessEntry3.apply();
                          NewprocessEntry4.apply();
                          NewprocessEntry5.apply();
                          NewprocessEntry6.apply();
                          NewprocessEntry7.apply();
                          NewprocessEntry8.apply();
                          NewprocessEntry9.apply();
                          NewprocessEntry10.apply();
                          NewprocessEntry11.apply();
                          NewprocessEntry12.apply();
                          NewprocessEntry13.apply();
                          NewprocessEntry14.apply();
                          NewprocessEntry15.apply();
                          NewprocessEntry16.apply();
                          NewprocessEntry17.apply();
                          NewprocessEntry18.apply();
                          NewprocessEntry19.apply();
                          NewprocessEntry20.apply();
                          NewprocessEntry21.apply();
                          NewprocessEntry22.apply();
                          NewprocessEntry23.apply();
                          NewprocessEntry24.apply();
                          NewprocessEntry25.apply();
                          NewprocessEntry26.apply();
                          NewprocessEntry27.apply();
                          NewprocessEntry28.apply();
                          NewprocessEntry29.apply();
                          NewprocessEntry30.apply();
                          NewprocessEntry31.apply();
                          NewprocessEntry32.apply();


                        drop_table.apply(); /// isAggregator / agtr_complte / resubmit_flag 매치키에 추가 
                        modify_packet_bitmap_table.apply(); /// isAggregator / agtr_complte 매치키에 추가
                        outPort_table.apply(); /// isAggregator / agtr_complte 매치키에 추가


                    } else {
                        /* tag collision bit in incoming one */
                        // if not empty
                        if (hdr.p4ml.isResend == 0) {
                        }
                        outPort_table.apply();
                    }
                }
            }
    } else {
        if(standard_metadata.ingress_port != 0){
                // Interfaces we care about:
                // N3 (from base station) - GTPU - match on outer IP dst
                // N6 (from internet) - no GTPU - match on IP header dst
                if (interfaces.apply().hit) {
                    // Normalize so the UE address/port appear as the same field regardless of direction
                    if (md.direction == Direction.UPLINK) {
                        md.ue_addr = hdr.inner_ipv4.srcAddr;
                        md.inet_addr = hdr.inner_ipv4.dstAddr;
                        md.ue_l4_port = md.l4_sport;
                        md.inet_l4_port = md.l4_dport;
                        md.ip_proto = hdr.inner_ipv4.protocol;

                        sessions_uplink.apply();
                        // Need Aggregation hear!
                    } else if (md.direction == Direction.DOWNLINK) {
                        md.ue_addr = hdr.ipv4.dstAddr;
                        md.inet_addr = hdr.ipv4.srcAddr;
                        md.ue_l4_port = md.l4_dport;
                        md.inet_l4_port = md.l4_sport;
                        md.ip_proto = hdr.ipv4.protocol;

                        sessions_downlink.apply();
                        tunnel_peers.apply();
                    }

                    // applications.apply();

                    if (md.direction == Direction.UPLINK) {
                        terminations_uplink.apply();
                    }  else if (md.direction == Direction.DOWNLINK) {
                        terminations_downlink.apply();
                    }

                    // Perform whatever header removal the matching in
                    // sessions_* and terminations_* required.
                    if (md.needs_gtpu_decap) {
                        gtpu_decap();
                    }
                   
                    if (md.needs_tunneling) {
                        if (md.tunnel_out_qfi == 0) {
                            // 4G
                            do_gtpu_tunnel();
                        } else {
                            // 5G
                            do_gtpu_tunnel_with_psc();
                        }
                    }
                    if (md.needs_dropping) {
                        do_drop();
                    }
                }
            }
        forward.apply();
        // or Routing.apply(hdr, md, standard_metadata);
        }
    }
}


control NativeUP4Egress(
    inout header_t hdr,
    inout metadata_t md,
    inout standard_metadata_t standard_metadata) 
{

    bit<32> zero_index_for_eg = 0;
    bit<32> deq_qdepth_modified = (bit<32>)standard_metadata.deq_qdepth;
    bit<32> eg_md_mdata_qdepth = (bit<32>)md.mdata.qdepth;

    #include "include/egress_registers.p4"
    #include "include/egress_actions.p4"
    #include "include/egress_tables.p4"


    action do_recirculation(){
        recirculate_preserving_field_list(0);
    }
    
    action header_validation_action(){
        hdr.p4ml_entries.setInvalid();
        // hdr.p4ml_entries_1bit.setValid();      
    }

    table header_validation_table{
        key={
        }
        actions = {
            header_validation_action();
        }
        default_action = header_validation_action();
    }
    
    action nop()
    {
    }

    // teid, outer ip, inner ip 변경해주는 table 및 action 작성
    action do_modify(ipv4_addr_t outer_src_addr, ipv4_addr_t outer_dst_addr,
                     ipv4_addr_t inner_src_addr, ipv4_addr_t inner_dst_addr,
                     teid_t teid){
        hdr.ipv4.srcAddr = outer_src_addr;
        hdr.ipv4.dstAddr = outer_dst_addr;
        hdr.inner_ipv4.srcAddr = inner_src_addr;
        hdr.inner_ipv4.dstAddr = inner_dst_addr;
        hdr.gtpu.teid = teid;
    }
    
    table Modify_hdr{
        key = {
            standard_metadata.egress_port: exact;
        }
        actions = {
            do_modify;
            nop;
        }
        default_action = nop;
    }


    apply{
        if(standard_metadata.egress_port == 68){
            do_recirculation();
        }
        Modify_hdr.apply();
    }
}

V1Switch(
    NativeUP4Parser(),
    VerifyChecksumImpl(),
    NativeUP4Ingress(),
    NativeUP4Egress(),
    ComputeChecksumImpl(),
    NativeUP4Deparser()
) main;
