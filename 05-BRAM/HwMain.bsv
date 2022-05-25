import FIFO::*;
import BRAM::*;
import Clocks::*;
import Vector::*;
import BRAMFIFO::*;
import BramCtl::*;

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

    Vector#(2, BramCtlIfc#(128, 2048, 11)) bram_ctl <- replicateM(mkBramCtl);
    Reg#(Bit#(11)) bram_idx_0 <- mkReg(0);
    Reg#(Bit#(11)) bram_idx_1 <- mkReg(0);
    Reg#(Bit#(11)) read_bram_cnt <- mkReg(0);
    Reg#(Bit#(11)) target_bram_cnt <- mkReg(1024);

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
                bram_ctl[0].write_req(bram_idx_0, rd);
                bram_idx_0 <= bram_idx_0 + 1;
            end
            1 : begin
                bram_ctl[1].write_req(bram_idx_1, rd);
                bram_idx_1 <= bram_idx_1 + 1;
            end
        endcase
    endrule

    rule readReqToBRAM(read_bram_cnt != target_bram_cnt && bram_idx_1 == 1024);
        bram_ctl[0].read_req(truncate(read_bram_cnt));
        bram_ctl[1].read_req(truncate(read_bram_cnt));
        read_bram_cnt <= read_bram_cnt + 1;
    endrule
    rule getDataFromBRAM;
        Bit#(128) d1 = 0;
        Bit#(128) d2 = 0;
        d1 <- bram_ctl[0].get;
        d2 <- bram_ctl[1].get;

        matrix_aQ.enq(d1);
        matrix_bQ.enq(d2);
    endrule

    rule addMatrix(bram_idx_0 == bram_idx_1 && bram_idx_0 != 0);
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
