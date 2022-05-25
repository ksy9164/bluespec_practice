import Clocks::*;
import ClockImport::*;
import DefaultValue::*;
import Clocks::*;

import FIFO::*;

// PCIe stuff
import PcieImport::*;
import PcieCtrl::*;
import PcieCtrl_bsim ::*;

// DRAM stuff
import DDR3Sim::*;
import DDR3Controller::*;
import DDR3Common::*;
import DRAMController::*;

import HwMain::*;

interface TopIfc;
    (* always_ready *)
    interface PcieImportPins pcie_pins;
    (* always_ready *)
    method Bit#(4) led;

    interface DDR3_Pins_1GB pins_ddr3;
endinterface

(* no_default_clock, no_default_reset *)
module mkProjectTop #(
    Clock pcie_clk_p, Clock pcie_clk_n, Clock emcclk,
    Clock sys_clk_p, Clock sys_clk_n,
    Reset pcie_rst_n
) (TopIfc);

    /* PCIe Part */
    PcieImportIfc pcie <- mkPcieImport(pcie_clk_p, pcie_clk_n, pcie_rst_n, emcclk);
    Clock pcie_clk_buf = pcie.sys_clk_o;
    Reset pcie_rst_n_buf = pcie.sys_rst_n_o;

    PcieCtrlIfc pcieCtrl <- mkPcieCtrl(pcie.user, clocked_by pcie.user_clk, reset_by pcie.user_reset);

    /* DRAM part */
    ClockGenIfc clk_200mhz_import <- mkClockIBUFDSImport(sys_clk_p, sys_clk_n);
    Clock sys_clk_200mhz = clk_200mhz_import.gen_clk;
    ClockGenIfc sys_clk_200mhz_buf_import <- mkClockBUFGImport(clocked_by sys_clk_200mhz);
    Clock sys_clk_200mhz_buf = sys_clk_200mhz_buf_import.gen_clk;
    Clock ddr_buf = sys_clk_200mhz_buf;
    Reset ddr3ref_rst_n <- mkAsyncResetFromCR(4, ddr_buf, reset_by pcieCtrl.user.user_rst);

    DDR3Common::DDR3_Configure ddr3_cfg = defaultValue;
    ddr3_cfg.reads_in_flight = 32;   // adjust as needed
    DDR3_Controller_1GB ddr3_ctrl <- mkDDR3Controller_1GB(ddr3_cfg, ddr_buf, clocked_by ddr_buf, reset_by ddr3ref_rst_n);

    /* Create DRAM Controller */
    DRAMControllerIfc dramController <- mkDRAMController(ddr3_ctrl.user, clocked_by pcieCtrl.user.user_clk, reset_by pcieCtrl.user.user_rst);

    /* Create Hardware-Main and Connect with PCIe and DRAM */
    HwMainIfc hwmain <- mkHwMain(pcieCtrl.user, dramController.user, clocked_by pcieCtrl.user.user_clk, reset_by pcieCtrl.user.user_rst);

// Interfaces ////
interface PcieImportPins pcie_pins = pcie.pins;

interface DDR3_Pins_1GB pins_ddr3 = ddr3_ctrl.ddr3;

method Bit#(4) led;
    return 0;
endmethod
endmodule

module mkProjectTop_bsim (Empty);
    Clock curclk <- exposeCurrentClock;

    PcieCtrlIfc pcieCtrl <- mkPcieCtrl_bsim;

    let ddr3_ctrl_user <- mkDDR3Simulator;
    DRAMControllerIfc dramController <- mkDRAMController(ddr3_ctrl_user);
    HwMainIfc hwmain <- mkHwMain(pcieCtrl.user, dramController.user);
endmodule
