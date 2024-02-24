from scapy.all import *
from scapy.contrib import gtp
from scapy.layers.inet import IP, UDP
from time import sleep
import sys
import argparse
import threading
import argparse
# import numpy as np
import math

parser = argparse.ArgumentParser(description='parser')
parser.add_argument('--i', required=False, type=str, default='eth0', help='interface')
parser.add_argument('--bitmap', required=False, type=int, default=1, help='bitmap')
parser.add_argument('--agtr_time', required=False, type=int, default=1, help='')
parser.add_argument('--appIDandSeqNum', required=False, type=int, default=2, help='')     
parser.add_argument('--appID', required=False, type=int, default=1, help='')     
parser.add_argument('--seqNum', required=False, type=int, default=1, help='')     
parser.add_argument('--agtr_index', required=False, type=int, default=1, help='')         # 
parser.add_argument('--isresend', required=False, type=int, default=0, help='')


parser.add_argument('--dst_mac', required=False, type=str, default="0c:c4:7a:63:ff:ff", help='')
parser.add_argument('--src_ip', required=False, type=str, default="20.10.0.1", help='')
parser.add_argument('--dst_ip', required=False, type=str, default="20.10.0.254", help='')
parser.add_argument('--packet_number', required=True, type=int, default=100, help='')
parser.add_argument('--logging', required=True, type=str, default="False", help='')

pkts = []
UEID = 2
teid = 100

UE_IP = "172.20.0.2"
PS_IP = "172.18.0.2"
gNB_IP = "172.20.0.1"
N3_iface = "172.17.0.1"

MAX_AGGREGATOR = 40000

global window_queue, ACK_queue, window_size, head, tail, last_acked, current_last_acked, timeout, cnt, init_time, last_packet_flag, logging_file
window_queue = []
ACK_queue = []
window_size = 1
head = 0
tail = 20
last_acked = 0
current_last_acked = 0
timeout = 10
cnt = 0
init_time = 0
last_packet_flag = 0

UE_PORT = 400
PDN_PORT = 80
GPDU_PORT = 2152

args = parser.parse_args()
lock = threading.Lock() 

dst_mac = args.dst_mac
src_ip = args.src_ip
dst_ip = args.dst_ip
logging = args.logging

file_name = "/home/IITP/BS/INA/DelayForBS2_%d_INA.txt" % args.packet_number
logging_file = open(file_name,"w")

class p4ml(Packet):
    """ ATP Header. """
    
    name = "p4ml"

    fields_desc = [
        BitField('bitmap', 1, 32), # Worker Bitmap
        ByteField('agtr_time', 2),  # The number of workers
        BitField('overflow', 0, 1),     # Switch - Overflow
        BitField('PSIndex', 0, 2),      # Index of PS
        BitField('dataIndex', 0, 1),    # 1: Data  / 0: 
        BitField('ECN', 0, 1),          # Switch - ECN marking
        BitField('isResend', 0, 1), 
        BitField('isWCollision', 0, 1), # Switch - Hash collsion
        BitField('isACK', 0, 1),        # 1:Global gradient packet / 0:Local gradient packet
        BitField('appID', 1, 16),
        BitField('SeqNum', 0, 16),
        BitField('padding', 0, 6),
        BitField('quantization_level', 2, 2)
    ]
    
class p4ml_agtr_index(Packet):
    """ ATP aggregator index Header. """
    
    name = "p4ml_agtr_index"

    fields_desc = [
        BitField('p4ml_agtr_index', 0, 16), 
    ]

class p4ml_agtr_index_1(Packet):
    """ ATP aggregator index Header. """
    
    name = "p4ml_agtr_index"

    fields_desc = [
        BitField('p4ml_agtr_index', 0, 16), 
    ]

class entry(Packet):
    """ entry Header. """
    
    name = "entry"

    fields_desc = [
        SignedIntField('data0', 0),
        SignedIntField('data1', 1),
        SignedIntField('data2', 2),
        SignedIntField('data3', 3),
        SignedIntField('data4', 4),
        SignedIntField('data5', 5),
        SignedIntField('data6', 6),
        SignedIntField('data7', 7),
        SignedIntField('data8', 8),
        SignedIntField('data9', 9),
        SignedIntField('data10', 10),
        SignedIntField('data11', 11),
        SignedIntField('data12', 12),
        SignedIntField('data13', 13),
        SignedIntField('data14', 14),
        SignedIntField('data15', 15),
        SignedIntField('data16', 16),
        SignedIntField('data17', 17),
        SignedIntField('data18', 18),
        SignedIntField('data19', 19),
        SignedIntField('data20', 20),
        SignedIntField('data21', 21),
        SignedIntField('data22', 22),
        SignedIntField('data23', 23),
        SignedIntField('data24', 24),
        SignedIntField('data25', 25),
        SignedIntField('data26', 26),
        SignedIntField('data27', 27),
        SignedIntField('data28', 28),
        SignedIntField('data29', 29),
        SignedIntField('data30', 30),
        SignedIntField('data31', 31)
    ]

class entry_1(Packet):
    """ entry Header. """
    
    name = "entry2"

    fields_desc = [
        SignedIntField('data0', 0),
        SignedIntField('data1', -1),
        SignedIntField('data2', -2),
        SignedIntField('data3', -3),
        SignedIntField('data4', -4),
        SignedIntField('data5', -5),
        SignedIntField('data6', -6),
        SignedIntField('data7', -7),
        SignedIntField('data8', -8),
        SignedIntField('data9', -9),
        SignedIntField('data10', -10),
        SignedIntField('data11', -11),
        SignedIntField('data12', -12),
        SignedIntField('data13', -13),
        SignedIntField('data14', -14),
        SignedIntField('data15', -15),
        SignedIntField('data16', -16),
        SignedIntField('data17', -17),
        SignedIntField('data18', -18),
        SignedIntField('data19', -19),
        SignedIntField('data20', -20),
        SignedIntField('data21', -21),
        SignedIntField('data22', -22),
        SignedIntField('data23', -23),
        SignedIntField('data24', -24),
        SignedIntField('data25', -25),
        SignedIntField('data26', -26),
        SignedIntField('data27', -27),
        SignedIntField('data28', -28),
        SignedIntField('data29', -29),
        SignedIntField('data30', -30),
        SignedIntField('data31', -31)
    ]

def crc16(data):
    xor_in = 0x0000  # initial value
    xor_out = 0x0000  # final XOR value
    poly = 0x8005  # generator polinom (normal form)

    reg = xor_in
    for octet in data:
        # reflect in
        for i in range(8):
            topbit = reg & 0x8000
            if octet & (0x80 >> i):
                topbit ^= 0x8000
            reg <<= 1
            if topbit:
                reg ^= poly
        reg &= 0xFFFF
        # reflect out
    return reg ^ xor_out

def receive_packet():

    iface = 'eth0'
    bind_layers(IP, p4ml)
    bind_layers(p4ml, p4ml_agtr_index)
    bind_layers(p4ml_agtr_index, p4ml_agtr_index_1)
    bind_layers(p4ml_agtr_index_1, entry)
    bind_layers(entry, entry_1)
    
    # print("sniffing on %s" % iface)
    sniff(iface = iface, prn = lambda x: handle_pkt(x))

def handle_pkt(pkt):
    global cnt, last_packet_flag, logging_file
    cnt += 1
    recv_time = time.time()
    delay_time = recv_time - init_time
    sys.stdout.flush()
    data = "%f \n"%delay_time
    logging_file.write(data)
    if p4ml in pkt:
        # if pkt[p4ml].isACK == 1:   
        if pkt[p4ml].dataIndex == 1:   
            cnt += 1 
            seq_num = pkt[p4ml].SeqNum
            print(f"{seq_num}th packet")
            if seq_num == args.packet_number:
                last_packet_flag = 1
                print(f"Delay: {delay_time}")
            if args.logging:
                if seq_num == (args.packet_number -1) : 
                    pkt.show()
    
def generate_packets(packet_num):
    pkts = []
    for i in range (1,packet_num+1):
        aggr_index_1 = i %40000
        aggr_index_2 = (i + MAX_AGGREGATOR/2)%40000
        pre_pkt = Ether(src='00:00:00:00:00:00', dst=args.dst_mac) / IP(src=gNB_IP, dst=N3_iface,proto = 17) / UDP(dport = GPDU_PORT) / gtp.GTP_U_Header(gtp_type=0xff, teid = teid+UEID)
        pkt = pre_pkt / IP(src=UE_IP, dst=PS_IP,proto = 100) / p4ml(SeqNum=i,isResend=0) / p4ml_agtr_index(p4ml_agtr_index=int(aggr_index_1)) / p4ml_agtr_index_1(p4ml_agtr_index=int(aggr_index_2)) / entry() / entry_1()
        pkts.append(pkt)
    return pkts

def send_and_receive():
    global window_queue, ACK_queue, window_size, head, tail, last_acked, current_last_acked, init_time, logging_file
    init_time = time.time()
    receive_thread = threading.Thread(target=receive_packet, args=())
    receive_thread.daemon = True    
    receive_thread.start()

    # checkloss_thread = threading.Thread(target=check_pkt_loss, args=())
    # checkloss_thread.daemon = True    
    # checkloss_thread.start()
    
    num_packets = args.packet_number
    pkts = generate_packets(num_packets)

    count = 0
    for i in range(0, num_packets):
        sendp(pkts[i],iface='eth0',verbose=False)
        print(f"{i+1} packet is sent")
        # if pkts[i][p4ml].SeqNum % 50 ==0:
        #     pkts[i].show()
        # count += 1
    while True:
        if last_packet_flag == 1:
            logging_file.close()
            break

send_and_receive()
