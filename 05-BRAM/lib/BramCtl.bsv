package BramCtl;

import BRAM::*;
import FIFO::*;

interface BramCtlIfc#(numeric type data_size, numeric type table_size, numeric type index_size);
    method Action read_req(Bit#(index_size) addr);
    method Action write_req(Bit#(index_size) addr, Bit#(data_size) data);
    method ActionValue#(Bit#(data_size)) get;
endinterface

function BRAMRequest#(Bit#(index_size), Bit#(data_size)) makeRequest(Bool write, Bit#(index_size) addr, Bit#(data_size) data);
    return BRAMRequest{
        write: write,
        responseOnWrite: False,
        address: addr,
        datain: data
    };
endfunction

module mkBramCtl (BramCtlIfc#(data_size, table_size, index_size));
    FIFO#(Bit#(index_size)) readQ <- mkFIFO;
    FIFO#(Tuple2#(Bit#(index_size), Bit#(data_size))) writeQ <- mkFIFO;
    FIFO#(Bit#(data_size)) responseQ <- mkFIFO; // read response

    BRAM_Configure cfg = defaultValue;
    cfg.memorySize = valueOf(table_size);
    BRAM2Port#(Bit#(index_size), Bit#(data_size)) bram_server <- mkBRAM2Server(cfg);

    /* Rule start */
    rule writeReq;
        writeQ.deq;
        Tuple2#(Bit#(index_size), Bit#(data_size)) d = writeQ.first;

        Bit#(index_size) addr = tpl_1(d);
        Bit#(data_size) data = tpl_2(d);

        bram_server.portA.request.put(makeRequest(True, addr, data));
    endrule

    rule readReq;
        readQ.deq;
        Bit#(index_size) addr = readQ.first;

        bram_server.portB.request.put(makeRequest(False, addr, ?));
    endrule

    rule readData;
        Bit#(data_size) d <- bram_server.portB.response.get;
        responseQ.enq(d);
    endrule

    /* Define method */
    method Action read_req(Bit#(index_size) addr);
        readQ.enq(addr);
    endmethod
    
    method Action write_req(Bit#(index_size) addr, Bit#(data_size) data);
        writeQ.enq(tuple2(addr, data));
    endmethod

    method ActionValue#(Bit#(data_size)) get;
        responseQ.deq;
        return responseQ.first;
    endmethod

endmodule

endpackage
