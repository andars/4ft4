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

    dut._log.info("begin test of wb-controlled system")

    # write pattern to start of ram
    ram_base = 0x10000
    cmds = [WBOp(ram_base + i, 0xa) for i in range(16)]
    await wb.send_cycle(cmds)

    # LDM 5
    # FIM 0P 0
    # SRC 0P
    # WRM
    program = [0xd5, 0x20, 0x00, 0x21, 0xe0]

    # write the program at an offset because the wb writes
    # currently will race with the cpu (which will start at 0).
    offset = 10

    cmds = [WBOp(i + offset, program[i]) for i in range(len(program))]

    await wb.send_cycle(cmds)

    # give the cpu some time to run
    await ClockCycles(dut.clock, 8 * 16)

    # read back ram and check that it has not changed
    cmds = [WBOp(ram_base + i) for i in range(16)]
    responses = await wb.send_cycle(cmds)
    values = [transaction.datrd for transaction in responses]
    dut._log.info("read {}".format([hex(v) for v in values]))
    assert values == [0xa for i in range(16)]

    # write values to ram
    ram_base = 0x10000
    cmds = [WBOp(ram_base + i, i) for i in range(16)]
    await wb.send_cycle(cmds)

    # then read them back and verify
    cmds = [WBOp(ram_base + i) for i in range(16)]
    responses = await wb.send_cycle(cmds)

    values = [transaction.datrd for transaction in responses]
    dut._log.info("read {}".format([hex(v) for v in values]))
    assert values == [i for i in range(16)]
