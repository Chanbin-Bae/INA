#ifndef _COMMON_
#define _COMMON_

// RegisterAction<bit<32>, _, bit<32>>(agtr_time) cleaning_agtr_time  = {
//     void apply(inout bit<32> value){
//         value = 0;
//     }
// };

// RegisterAction<bit<32>, _, bit<32>>(ecn_register) cleaning_ecn  = {
//     void apply(inout bit<32> value){
//         value = 0;
//     }
// };


// RegisterAction<bit<32>, _, bit<32>>(bitmap) cleaning_bitmap  = {
//     void apply(inout bit<32> value){
//         value = 0;
//     }
// };
// RegisterAction<bit<32>, _, bit<32>>(bitmap) read_write_bitmap  = {
//     void apply(inout bit<32> value, out bit<32> read_value){
//         value = value | hdr.p4ml.bitmap; // ig_md.mdata.bitmap
//         read_value = value;
//     }
// };
// RegisterAction<bit<32>, _, bit<32>>(bitmap) read_write_bitmap_resend  = {
//     void apply(inout bit<32> value, out bit<32> read_value){
//         value = 0; 
//         read_value = value; // ig_md.mdata.bitmap
//     }
// };


// // RegisterAction<bit<32>, _, bit<32>>(appID_and_Seq) check_app_id_and_seq  = {
// //     void apply(inout bit<32> value, out bit<32> read_value){
// //         if (value[31:16] - (bit<16>)hdr.p4ml.quantization_level >= 0 && value[15:0] != hdr.p4ml.appIDandSeqNum[15:0]){ // value[31:24] < hdr.p4ml.appIDandSeqNum[31:24]
// //             value = hdr.p4ml.appIDandSeqNum;
// //             read_value = value; // ig_md.mdata.isMyAppIDandMyCurrentSeq;
// //         }
// //     }
// // };

// // RegisterAction<value_pair_t, _, bit<32>>(appID_and_Seq_pair) check_app_id_and_seq = { ///
// //     void apply(inout value_pair_t value, out bit<32> read_value) {
// //         if (value.quantization_level - (bit<32>)hdr.p4ml.quantization_level >= 0 && value.appID_and_Seq != hdr.p4ml.appIDandSeqNum){

// //         }
// //         else{
// //             value.appID_and_Seq = hdr.p4ml.appIDandSeqNum;
// //             read_value = value.appID_and_Seq;
// //         }
// //     }
// // };

// RegisterAction<value_pair_t, _, bit<32>>(appID_and_Seq_pair) check_app_id_and_seq = {
//     void apply(inout value_pair_t value, out bit<32> read_value) {
//         // bit<32> quantization_diff = value.quantization_level - (bit<32>)hdr.p4ml.quantization_level;
//         // bool same_app_id_and_seq = value.appID_and_Seq != hdr.p4ml.appIDandSeqNum;

//         if (value.quantization_level > 0 ) {
//             // ...
//         } else {
//             value.appID_and_Seq = hdr.p4ml.appIDandSeqNum;
//             // read_value = value.appID_and_Seq;
//         }
//         read_value = value.appID_and_Seq;
//     }
// };







// RegisterAction<bit<8>, _, bit<8>>(quantization_level) check_quantization_level  = {
//     void apply(inout bit<8> value, out bit<8> read_value){
//         if (value - (bit<8>)hdr.p4ml.quantization_level >= 128){   // 32bit -> preempt
//             value = (bit<8>)hdr.p4ml.quantization_level;
//             read_value = 1; // ig_md.mdata.steal = 1;
//         }
//         // if (value == 1 && hdr.p4ml.quantization_level == 0){   // 32bit -> preempt
//         //     value = (bit<8>)hdr.p4ml.quantization_level + 1;
//         //     read_value = 1; // ig_md.mdata.steal = 1;
//         // }
//         else{
//             read_value = 0; // when late 32bit or 1bit -> can't take away
//         }
//     }
// };

// RegisterAction<bit<32>, _, bit<32>>(appID_and_Seq) check_app_id_and_seq_resend  = {
//     void apply(inout bit<32> value, out bit<32> read_value){
//         if (value == hdr.p4ml.appIDandSeqNum){
//             value = 0;
//             read_value = value; // ig_md.mdata.isMyAppIDandMyCurrentSeq;
//         }
//     }
// };





// RegisterAction<bit<32>, _, bit<32>>(appID_and_Seq) clean_app_id_and_seq  = {
//     void apply(inout bit<32> value, out bit<32> read_value){
//         if (value == hdr.p4ml.appIDandSeqNum){
//             value = 0;
//             read_value = hdr.p4ml.appIDandSeqNum; // ig_md.mdata.isMyAppIDandMyCurrentSeq;
//         }
//     }
// };

// RegisterAction<bit<32>, _, bit<32>>(agtr_time) check_agtrTime  = {
//     void apply(inout bit<32> value, out bit<32> read_value){
//         if (ig_md.mdata.isAggregate != 0){
//             value = value + 1;
//         }
//         read_value = value; // ig_md.mdata.current_agtr_time; 
//     }
// };

// RegisterAction<bit<32>, _, bit<32>>(agtr_time) check_resend_agtrTime  = {
//     void apply(inout bit<32> value, out bit<32> read_value){
//         if (ig_md.mdata.isAggregate != 0){
//             value = 0;
//         }
//         else{
//             value = 0;
//         }
//         read_value = (bit<32>)hdr.p4ml.agtr_time; // ig_md.mdata.mdata.current_agtr_time; 
//     }
// };

// //Egress
// // RegisterAction<bit<32>, _, bit<32>>(dqueue_alert_threshold) do_comp_qdepth  = {
// //     void apply(inout bit<32> value, out bit<32> read_value){
// //         if (eg_intr_md.deq_qdepth >= 1000){
// //             read_value = eg_intr_md.deq_qdepth; // eg_md.mdata.qdepth;
// //         }
// //     }
// // };

// RegisterAction<bit<32>, _, bit<32>>(ecn_register) do_check_ecn  = {
//     void apply(inout bit<32> value, out bit<32> read_value){
//         if (value == 1){
//             value = value | ig_md.mdata.is_ecn;
//             read_value = (bit<32>)hdr.p4ml.ECN; // ig_md.mdata.value_one; 
//         }
//     }
// };



// Action
action process_bitmap() {
    bit<32> value_for_bitmap = 0;
    // bit<32> index_for_register = (bit<32>)hdr.p4ml_agtr_index.agtr;
    bitmap.read(value_for_bitmap, index_for_register);
    value_for_bitmap = value_for_bitmap | hdr.p4ml.bitmap;
    bitmap.write(index_for_register, value_for_bitmap);
    md.mdata.bitmap = value_for_bitmap;
    md.mdata.isAggregate = hdr.p4ml.bitmap & md.mdata.bitmap; ////
    md.mdata.integrated_bitmap = hdr.p4ml.bitmap | md.mdata.bitmap; ////
}

action process_bitmap_resend() {
    bit<32> value_for_bitmap_resend;
    bitmap.read(value_for_bitmap_resend ,index_for_register);
    md.mdata.bitmap = value_for_bitmap_resend;
    bitmap.write(index_for_register,0);
    // md.mdata.bitmap = 0;
    md.mdata.isAggregate = hdr.p4ml.bitmap & md.mdata.bitmap; ////
    md.mdata.integrated_bitmap = hdr.p4ml.bitmap | md.mdata.bitmap; ////
}

// TODO:
action check_aggregate_and_forward() {
    // this is is for aggregation needed checking
    md.mdata.isAggregate = hdr.p4ml.bitmap & md.mdata.bitmap; ////-
    md.mdata.integrated_bitmap = hdr.p4ml.bitmap | md.mdata.bitmap; ////-
}

action clean_agtr_time() {
    agtr_time.write(index_for_register,0);
}

action clean_ecn() {
    ecn_register.write(index_for_register, 0);
}

action clean_bitmap() {
    // cleaning_bitmap.execute(hdr.p4ml_agtr_index.agtr);
    bitmap.write(index_for_register, 0);
}

action multicast(bit<16> group) {
    standard_metadata.mcast_grp = group;
}


// RegisterAction<value_pair_t, _, bit<32>>(appID_and_Seq_pair) check_app_id_and_seq = {
//     void apply(inout value_pair_t value, out bit<32> read_value) {
//         // bit<32> quantization_diff = value.quantization_level - (bit<32>)hdr.p4ml.quantization_level;
//         // bool same_app_id_and_seq = value.appID_and_Seq != hdr.p4ml.appIDandSeqNum;

//         if (value.quantization_level > 0 ) {
//             // ...
//         } else {
//             value.appID_and_Seq = hdr.p4ml.appIDandSeqNum;
//             // read_value = value.appID_and_Seq;
//         }
//         read_value = value.appID_and_Seq;
//     }
// };

// action check_appID_and_seq() {
//     ig_md.mdata.isMyAppIDandMyCurrentSeq = (bit<16>)check_app_id_and_seq.execute(hdr.p4ml_agtr_index.agtr);
//     //modify_field(mdata.qdepth, 0);   
// }

//////////////////////////////////TODO modify____CHECK!!!!!!!!!!!!!!!!!!!!!!
// action check_appID_and_seq() {
//     // hdr.p4ml_agtr_index.agtr : 16bit
//     // hdr.p4ml.appIDandSeqNum : 32bit
//     appID_and_Seq_pair.write(index_for_register, hdr.p4ml.appIDandSeqNum);
//     appID_and_Seq.write(index_for_register, hdr.p4ml.appIDandSeqNum);
//     md.mdata.isMyAppIDandMyCurrentSeq = (bit<16>) hdr.p4ml.appIDandSeqNum;
// }

action check_appID_and_seq() {
    // hdr.p4ml_agtr_index.agtr : 16bit
    // hdr.p4ml.appIDandSeqNum : 32bit
    appID_and_Seq_pair.write(index_for_register, hdr.p4ml.appIDandSeqNum);
    appID_and_Seq.write(index_for_register, hdr.p4ml.appIDandSeqNum); // should be in ?_0516
}

////////////////////////////////////////////////////////////////ToDo modifiy

action check_appID_and_seq_resend() {
    // ig_md.mdata.isMyAppIDandMyCurrentSeq = (bit<16>)check_app_id_and_seq_resend.execute(hdr.p4ml_agtr_index.agtr);

    md.mdata.isMyAppIDandMyCurrentSeq = (bit<16>) hdr.p4ml.appIDandSeqNum ;
    appID_and_Seq.write(index_for_register, 0);
    // md.mdata.isMyAppIDandMyCurrentSeq = 0;
 //   modify_field(mdata.qdepth, 0);   
}

action clean_appID_and_seq() {
    appID_and_Seq.write(index_for_register, 0);
    md.mdata.isMyAppIDandMyCurrentSeq = (bit<16>)hdr.p4ml.appIDandSeqNum;
}

action check_agtr_time_nonzero() {
    // ig_md.mdata.current_agtr_time = (bit<8>)check_agtrTime.execute(hdr.p4ml_agtr_index.agtr);
    // ig_md.mdata.agtr_complete = ~(ig_md.mdata.current_agtr_time ^ hdr.p4ml.agtr_time); ///
    agtr_time.read(Check_for_aggregate, index_for_register);
    index_for_current_agtr_time = Check_for_aggregate + 1;
    agtr_time.write(index_for_register,index_for_current_agtr_time);
    md.mdata.current_agtr_time = (bit<8>) index_for_current_agtr_time;
    md.mdata.agtr_complete = ~(md.mdata.current_agtr_time ^ hdr.p4ml.agtr_time);    
}

action check_agtr_time_zero() {
    // ig_md.mdata.current_agtr_time = (bit<8>)check_agtrTime.execute(hdr.p4ml_agtr_index.agtr);
    // ig_md.mdata.agtr_complete = ~(ig_md.mdata.current_agtr_time ^ hdr.p4ml.agtr_time); ///
    agtr_time.read(Check_for_aggregate, index_for_register);
    md.mdata.current_agtr_time = (bit<8>)Check_for_aggregate;
    md.mdata.agtr_complete = ~(md.mdata.current_agtr_time ^ hdr.p4ml.agtr_time);
}

action check_resend_agtr_time() {
    agtr_time.write(index_for_register, 0);
    md.mdata.current_agtr_time = (bit<8>)hdr.p4ml.agtr_time;
    md.mdata.agtr_complete = ~(md.mdata.current_agtr_time ^ hdr.p4ml.agtr_time);
}

action modify_packet_bitmap() {
    // modify_field(p4ml.bitmap, mdata.integrated_bitmap);
    hdr.p4ml.bitmap = md.mdata.integrated_bitmap;
}

// egress actions

// action do_qdepth() {
//     eg_md.mdata.qdepth = do_comp_qdepth.execute(0);
// }

// action modify_ecn() {
//     // modify_field(p4ml.ECN, 1);
//     hdr.p4ml.ECN = 1;
// }

// action mark_ecn() {
//     // bit_or(mdata.is_ecn, mdata.qdepth, mdata.is_ecn);
//     eg_md.mdata.is_ecn = eg_md.mdata.qdepth | eg_md.mdata.is_ecn;
// }

// action modify_ipv4_ecn() {
//     // modify_field(ipv4.ecn, 3);
//     hdr.ipv4.ecn = 3;
// }

action check_ecn() {
    // ig_md.mdata.value_one = (bit<1>)do_check_ecn.execute(hdr.p4ml_agtr_index.agtr);
    
    ecn_register.write(index_for_register, Check_value);
    md.mdata.value_one = (bit<1>) hdr.p4ml.ECN;
}

action setup_ecn() {
    // modify_field(mdata.is_ecn, 1);    
    md.mdata.is_ecn = 1;
}

action tag_collision_incoming() {
    // modify_field(p4ml.isSWCollision, 1);
    // hdr.p4ml_bg.isSWCollision =  1;
    // modify_field(p4ml.bitmap, mdata.isMyAppIDandMyCurrentSeq);
}

action set_egr(bit<9> egress_spec) {
    // modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
    // ig_intr_md_for_tm.ucast_egress_port = egress_spec;
    // increase_p4ml_counter.execute(ig_intr_md.ingress_port);
    standard_metadata.egress_spec = egress_spec;
}

action set_egr_and_set_index(bit<9> egress_spec) {
    // modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
    // ig_intr_md_for_tm.ucast_egress_port = egress_spec;
    // modify_field(p4ml.dataIndex, 1);
    // hdr.p4ml.dataIndex = 1;
    // increase_p4ml_counter.execute(ig_intr_md.ingress_port);
    standard_metadata.egress_spec = egress_spec;
    hdr.p4ml.dataIndex = 1;
}

action agg_complete_and_broadcast(bit<16> group) {
    standard_metadata.mcast_grp = group;
}




action nop()
{
}

action drop_pkt() {
    // drop();
    // ig_intr_md_for_dprsr.drop_ctl = 1;
    mark_to_drop(standard_metadata);

}

// unused
// action increase_counter() {
//     increase_p4ml_counter.execute(0);
// }

action check_quantization_level_action() { ///
    quantization_level_const = (bit<8>) hdr.p4ml.quantization_level;
    quantization_level.write(index_for_register, quantization_level_const);
    md.mdata.preemption = 1;
}

table check_quantization_level_table { ///
    actions = {
        check_quantization_level_action;
    }
    default_action = check_quantization_level_action;
    size = 1;
}


table bitmap_table {
    actions =  {
        process_bitmap;
    }
    default_action = process_bitmap();
    size = 1;
}

table bitmap_resend_table {
    actions =  {
        process_bitmap_resend;
    }
    default_action = process_bitmap_resend();
    size = 1;
}

table bitmap_aggregate_table {
    actions =  {
        check_aggregate_and_forward;
    }
    default_action = check_aggregate_and_forward();
    size = 1;
}

table agtr_time_table_nonzero {
    actions =  {
        check_agtr_time_nonzero;
    }
    default_action = check_agtr_time_nonzero();
    size = 1;
}

table agtr_time_table_zero {
    actions =  {
        check_agtr_time_zero;
    }
    default_action = check_agtr_time_zero();
    size = 1;
}

table agtr_time_resend_table {
    actions =  {
        check_resend_agtr_time;
    }
    default_action = check_resend_agtr_time();
    size = 1;
}

table immd_outPort_table {
    key = {
        // p4ml.appIDandSeqNum mask 0xFFFF0000: exact;
        hdr.p4ml.appIDandSeqNum : ternary;

    }
    actions =  {
        set_egr;
    }
}

table outPort_table {
    key =  {
        // p4ml.appIDandSeqNum mask 0xFFFF0000: exact;
        hdr.p4ml.appIDandSeqNum : ternary;
        standard_metadata.ingress_port: exact;
        hdr.p4ml.dataIndex: exact;
        hdr.p4ml.PSIndex: exact;
        md.mdata.isAggregate : ternary; ///
        md.mdata.agtr_complete : ternary; ///
        md.mdata.isAlreadyCleared : ternary;
    }
    actions =  {
		nop;
        set_egr;
        set_egr_and_set_index;
        drop_pkt;
        agg_complete_and_broadcast; //
    }
    default_action = drop_pkt();
}

table bg_outPort_table {
    key =  {
        // useless here, just can't use default action for variable
        // hdr.p4ml_bg.isACK : exact;
    }
    actions =  {
        set_egr;
		nop;
    }
}

table multicast_table {
    key =  {
        hdr.p4ml.isACK: exact;
        // hdr.p4ml.appIDandSeqNum mask 0xFFFF0000: exact;
        hdr.p4ml.appIDandSeqNum : ternary;
        standard_metadata.ingress_port: exact;
        hdr.p4ml.dataIndex: exact;
    }
    actions =  {
        multicast; drop_pkt; set_egr_and_set_index;
    }
    default_action = drop_pkt();
}


table clean_agtr_time_table {
    actions =  {
        clean_agtr_time;
    }
    default_action = clean_agtr_time();
    size = 1;
}

table clean_ecn_table {
    actions =  {
        clean_ecn;
    }
    default_action = clean_ecn();
    size = 1;
}


table clean_bitmap_table {
    actions =  {
        clean_bitmap;
    }
    default_action = clean_bitmap();
    size = 1;
}

// /* Counter */
// Register<bit<32>, bit<32>>(1) p4ml_counter;

// RegisterAction<bit<32>, _, bit<32>>(p4ml_counter) increase_p4ml_counter = {
//     void apply(inout bit<32> value){
//         value = value + 1;
//     }
// };

// table forward_counter_table {
//         actions =  {
//         increase_counter;
//     }
//     default_action = increase_counter();
// }

table appID_and_seq_table {
        actions =  {
        check_appID_and_seq;
    }
    default_action = check_appID_and_seq();
}

table appID_and_seq_resend_table {
        actions =  {
        check_appID_and_seq_resend;
    }
    default_action = check_appID_and_seq_resend();
}

table clean_appID_and_seq_table {
        actions =  {
        clean_appID_and_seq;
    }
    default_action = clean_appID_and_seq();
}

table modify_packet_bitmap_table {
    key =  {
        hdr.p4ml.dataIndex: exact;
        md.mdata.isAggregate : ternary; ///
        md.mdata.agtr_complete : ternary; ///        
    }
        actions =  {
        modify_packet_bitmap; nop;
    }
    default_action = modify_packet_bitmap(); //
    // default_action = nop(); //
}

// table qdepth_table {
//     actions =  {
//         do_qdepth;
//     }
//     default_action = do_qdepth();
// }

// table modify_ecn_table {
//     actions =  {
//         modify_ecn;
//     }
//     default_action = modify_ecn();
// }

// table mark_ecn_ipv4_table {
//     actions =  {
//         modify_ipv4_ecn;
//     }
//     default_action = modify_ipv4_ecn();
// }

// unused
// table ecn_mark_table {
//     actions =  {
//         mark_ecn;
//     }
//     default_action = mark_ecn();
// }

table ecn_register_table {
    actions =  {
        check_ecn;
    }
    default_action = check_ecn();
}

table setup_ecn_table {
    actions =  {
        setup_ecn;
    }
    default_action = setup_ecn();
}

table forward {
    key =  {
        hdr.ethernet.dstAddr : exact;
    }
    actions =  {
        set_egr; nop; drop_pkt;
    }
    default_action = drop_pkt();
}

table drop_table {
    key =  {
        standard_metadata.ingress_port: exact;
        hdr.p4ml.dataIndex : exact;
        md.mdata.isAggregate : ternary; ///
        md.mdata.agtr_complete : ternary; ///
        standard_metadata.instance_type: exact; ///
    }
    actions =  {
        drop_pkt; set_egr; set_egr_and_set_index; nop;
    }
    // default_action = drop_pkt();
    default_action = nop();
}

table tag_collision_incoming_table {
    actions =  {
        tag_collision_incoming;
    }
    default_action = tag_collision_incoming();
}

#endif