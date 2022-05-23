import FIFO::*;
import Vector::*;

import "BDPI" function Bit#(32) bdpi_read_mat_a(Bit#(32) offset);
import "BDPI" function Bit#(32) bdpi_read_mat_b(Bit#(32) offset);

import "BDPI" function Action bdpi_put_result(Bit#(32)result);

typedef 64 Matrix_Size;

module mkMatrixAdd(Empty);
	Reg#(Bit#(32)) inputOffset <- mkReg(0);
	FIFO#(Bit#(32)) pushOutQ <- mkFIFO;

	rule addInput(inputOffset < fromInteger(valueof(Matrix_Size) * valueof(Matrix_Size)));
		Bit#(32) a_data = bdpi_read_mat_a(inputOffset);
		Bit#(32) b_data = bdpi_read_mat_b(inputOffset);
		inputOffset <= inputOffset + 1;
		if (inputOffset % fromInteger(valueof(Matrix_Size)) == 0) begin
		    $display("");
		end
		pushOutQ.enq(a_data + b_data);
	endrule

	rule getOutput;
	    pushOutQ.deq;
		bdpi_put_result(pushOutQ.first);
	endrule

	rule finish(inputOffset == fromInteger(valueof(Matrix_Size) * valueof(Matrix_Size)));
	        $finish;
	endrule
endmodule
