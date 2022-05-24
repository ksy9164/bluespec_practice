import Clocks::*;
import ClockImport::*;
import DefaultValue::*;

import PcieImport::*;
import PcieCtrl::*;
import PcieCtrl_bsim ::*;

import Clocks::*;
import FIFO::*;

import HwMain::*;

interface TopIfc;
	(* always_ready *)
	interface PcieImportPins pcie_pins;
	(* always_ready *)
	method Bit#(4) led;
endinterface

(* no_default_clock, no_default_reset *)
module mkProjectTop #(
	Clock pcie_clk_p, Clock pcie_clk_n, Clock emcclk,
	Clock sys_clk_p, Clock sys_clk_n,
	Reset pcie_rst_n
	) 
	(TopIfc);

    /* Create PCIe Interface */
    PcieImportIfc pcie <- mkPcieImport(pcie_clk_p, pcie_clk_n, pcie_rst_n, emcclk);
    PcieCtrlIfc pcieCtrl <- mkPcieCtrl(pcie.user, clocked_by pcie.user_clk, reset_by pcie.user_reset);

    /* Create Hardware-Main and Connect with PCIe */
    HwMainIfc hwmain <- mkHwMain(pcieCtrl.user, clocked_by pcieCtrl.user.user_clk, reset_by pcieCtrl.user.user_rst);

	// Interfaces ////
	interface PcieImportPins pcie_pins = pcie.pins;

	method Bit#(4) led;
		//return leddata;
		return 0;
	endmethod
endmodule

/* When you create bsim for simulation, this code will be executed */
module mkProjectTop_bsim (Empty);
	Clock curclk <- exposeCurrentClock;

	PcieCtrlIfc pcieCtrl <- mkPcieCtrl_bsim;

	HwMainIfc hwmain <- mkHwMain(pcieCtrl.user);
endmodule
