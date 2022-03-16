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
                        signals_dict={"cyc":  "wb_cyc_i",
                                      "stb":  "wb_strobe_i",
                                      "we":   "wb_we_i",
                                      "adr":  "wb_addr_i",
                                      "datwr":"wb_data_i",
                                      "datrd":"wb_data_o",
                                      "ack":  "wb_ack_o"
                                     })

    # reset
    dut.reset.value = 1
    await ClockCycles(dut.clock, 32)
    dut.reset.value = 0

    dut._log.info("begin test of ram wb backdoor")

    write_req = await wb.send_cycle([WBOp(0, 0xa), WBOp(1, 0xb), WBOp(0x10, 0xc), WBOp(0x40, 0xa)])
    read_req = await wb.send_cycle([WBOp(0), WBOp(1), WBOp(0x10), WBOp(0x40)])

    values = [transaction.datrd for transaction in read_req]
    dut._log.info("read {}".format([hex(v) for v in values]))

    assert values == [0xa, 0xb, 0xc, 0xa]
