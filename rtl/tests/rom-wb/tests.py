import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotbext.wishbone.driver import WBOp, WishboneMaster

async def rom_wb_test(dut, halt):
    # start a 100 MHz clock
    clock = Clock(dut.clock, round(1e3/100), units="ns")
    cocotb.start_soon(clock.start())

    wb = WishboneMaster(dut, None, dut.clock,
                        width=32,
                        signals_dict={"cyc":  "wb_cyc_i",
                                      "stb":  "wb_strobe_i",
                                      "we":   "wb_we_i",
                                      "adr":  "wb_addr_i",
                                      "datwr":"wb_data_i",
                                      "datrd":"wb_data_o",
                                      "ack":  "wb_ack_o"
                                     })

    dut.halt.value = halt

    # reset
    dut.reset.value = 1
    await ClockCycles(dut.clock, 32)
    dut.reset.value = 0

    dut._log.info("begin test of rom wb backdoor")

    write_req = await wb.send_cycle([WBOp(0, 0xab+halt), WBOp(4, 0xcb+halt), WBOp(0x40, 0xcf+halt), WBOp(0x54, 0xed+halt)])

@cocotb.test()
async def test_rom_wb_interface(dut):
    await rom_wb_test(dut, 0)

@cocotb.test()
async def test_rom_wb_interface_halted(dut):
    await rom_wb_test(dut, 1)
