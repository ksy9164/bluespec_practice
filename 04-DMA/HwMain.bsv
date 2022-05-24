import FIFO::*;
import BRAM::*;
import Clocks::*;
import Vector::*;
import BRAMFIFO::*;

import PcieCtrl::*;

interface HwMainIfc;
endinterface

typedef 4096 Matrix_Size;

module mkHwMain#(PcieUserIfc pcie) 
	(HwMainIfc);
    FIFO#(Tuple2#(Bit#(20), Bit#(32))) pcie_reqQ <- mkFIFO;
    FIFO#(Bit#(32)) dmaReadReqQ <- mkFIFO;

    FIFO#(Bit#(128)) matrix_aQ <- mkSizedBRAMFIFO(valueOf(Matrix_Size) / 4);
    FIFO#(Bit#(128)) matrix_bQ <- mkSizedBRAMFIFO(valueOf(Matrix_Size) / 4);
    FIFO#(Bit#(128)) resultQ <- mkFIFO;

    FIFO#(Bit#(32)) dmaWriteReqQ <- mkFIFO;
    FIFO#(Bit#(1)) dmaWriteDoneSignalQ <- mkFIFO;
    FIFO#(Bit#(1)) dmaReadDoneSignalQ <- mkFIFO;

    Reg#(Bit#(1)) targetMatrix <- mkReg(0);

    Reg#(Bit#(32)) readCnt <- mkReg(0);

    Reg#(Bit#(1)) dmaWriteHandle <- mkReg(0);
    Reg#(Bit#(32)) dmaWriteTarget <- mkReg(0);
    Reg#(Bit#(32)) dmaWriteCnt <- mkReg(0);

    rule getDataFromHost;
        let w <- pcie.dataReceive;
        let a = w.addr;
        let d = w.data;
        pcie_reqQ.enq(tuple2(a, d));
    endrule

    rule getPCIeData; // get from HOST
        pcie_reqQ.deq;
        Bit#(20) a = tpl_1(pcie_reqQ.first);
        Bit#(32) d = tpl_2(pcie_reqQ.first);

        let off = (a>>2);
        if ( off == 0 ) begin
            dmaReadReqQ.enq(d);
        end else if (off == 1) begin 
            targetMatrix <= 1;
        end else if (off == 2) begin
            dmaWriteReqQ.enq(d);
        end else begin
            $display("Wrong PCIe Signal");
        end
    endrule

    rule getReadReq(readCnt == 0);
        dmaReadReqQ.deq;
        Bit#(32) cnt = dmaReadReqQ.first;
        pcie.dmaReadReq(0, truncate(cnt)); // Read Request to DMA with (offset, number of words)
        readCnt <= cnt;
    endrule
    rule getDataFromDMA(readCnt != 0);
        Bit#(128) rd <- pcie.dmaReadWord;
        if (readCnt - 1 == 0) begin
            dmaReadDoneSignalQ.enq(1); // All Data from the Host(which is in DMA FIFO) has been received
        end
        readCnt <= readCnt - 1;

        case (targetMatrix)
            0 : begin
                matrix_aQ.enq(rd);
            end
            1 : begin
                matrix_bQ.enq(rd);
            end
        endcase
    endrule

    rule addMatrix;
        matrix_aQ.deq;
        matrix_bQ.deq;
        Bit#(128) a = matrix_aQ.first;
        Bit#(128) b = matrix_bQ.first;

        Bit#(128) t = 0;
        t[127:96] = a[127:96] + b[127:96];
        t[95:64] = a[95:64] + b[95:64];
        t[63:32] = a[63:32] + b[63:32];
        t[31:0] = a[31:0] + b[31:0];

        resultQ.enq(t);
    endrule

    /* Write back to DMA */
    rule getDmaWriteReq(dmaWriteHandle == 0);
        dmaWriteReqQ.deq;
        pcie.dmaWriteReq(0, truncate(dmaWriteReqQ.first));

        dmaWriteHandle <= 1;
        dmaWriteCnt <= 0;
        dmaWriteTarget <= dmaWriteReqQ.first;
    endrule
    rule putDataToDma(dmaWriteHandle != 0);
        resultQ.deq;
        Bit#(128) d = resultQ.first;
        pcie.dmaWriteData(d);

        if (dmaWriteCnt + 1 == dmaWriteTarget) begin // Requested Write is Done
            dmaWriteHandle <= 0;
            dmaWriteDoneSignalQ.enq(1);
        end else begin
            dmaWriteCnt <= dmaWriteCnt + 1;
        end
    endrule

    /* Giving DMA write done signal to the HOST */
    rule sendResultToHost;
        let r <- pcie.dataReq;
        let a = r.addr;
        let offset = (a>>2);
        if ( offset == 0 ) begin
            dmaReadDoneSignalQ.deq;
            pcie.dataSend(r, 1);
        end else begin
            dmaWriteDoneSignalQ.deq;
            pcie.dataSend(r, 1);
        end
    endrule
endmodule
