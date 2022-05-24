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

    FIFO#(Bit#(32)) matrix_a <- mkFIFO;
    FIFO#(Bit#(32)) matrix_b <- mkFIFO;

    FIFO#(Bit#(32)) resultQ <- mkSizedBRAMFIFO(valueOf(Matrix_Size));

	rule getDataFromHost;
		/* Get Request from Host to Read 32Bits Data */
		let w <- pcie.dataReceive;
		Bit#(20) a = w.addr;
		Bit#(32) d = w.data;

        /* We won't use Last 2-Bits for PCIe Address */
		Bit#(20) off = a >> 2;

		case (off)
		    0 : begin
		        matrix_a.enq(d);
		    end
		    1 : begin
		        matrix_b.enq(d);
		    end
		endcase
	endrule

	rule addData;
	    matrix_a.deq;
	    matrix_b.deq;
	    Bit#(32) a = matrix_a.first;
	    Bit#(32) b = matrix_b.first;

	    resultQ.enq(a + b);
	endrule

	rule sendDataToHost;
		/* Send Result to Host when They want to get Result */
		let r <- pcie.dataReq;
		let a = r.addr;
		let offset = (a>>2);

        /* We are Using Only 1 Channel */
		if (offset == 0) begin 
			pcie.dataSend(r, resultQ.first);
			resultQ.deq;
		end else begin
		    $display( "Wrong Request from channel %d", r.addr);
		end
	endrule
endmodule
