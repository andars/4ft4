import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotbext.wishbone.driver import WBOp, WishboneMaster

@cocotb.test()
async def test_uart_to_wishbone(dut):
    # start a 100 MHz clock
    clock = Clock(dut.clock, round(1e3/100), units="ns")
    cocotb.start_soon(clock.start())

    wb = WishboneMaster(dut, None, dut.clock,
                        width=32,
                        signals_dict={"cyc":  "cyc_i",
                                      "stb":  "strobe_i",
                                      "we":   "we_i",
                                      "adr":  "addr_i",
                                      "datwr":"data_i",
                                      "datrd":"data_o",
                                      "ack":  "ack_o"
                                     })

    # reset
    dut.reset.value = 1
    await ClockCycles(dut.clock, 32)
    dut.reset.value = 0

    dut._log.info("begin test of rom wb backdoor")

    write_req = await wb.send_cycle([WBOp(0, 0xab), WBOp(1, 0xcb), WBOp(0x10, 0xcf), WBOp(0x15, 0xed)])
