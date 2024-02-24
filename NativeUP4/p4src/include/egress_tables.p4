#ifndef _EGRESS_TABLES_
#define _EGRESS_TABLES_


table qdepth_table {
    actions =  {
        do_qdepth;
    }
    default_action = do_qdepth();
}

table modify_ecn_table {
    actions =  {
        modify_ecn;
    }
    default_action = modify_ecn();
}

table mark_ecn_ipv4_table {
    actions =  {
        modify_ipv4_ecn;
    }
    default_action = modify_ipv4_ecn();
}

#endif

