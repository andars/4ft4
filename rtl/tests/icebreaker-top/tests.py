import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_icebreaker_top(dut):
    # start a 12 MHz clock
    clock = Clock(dut.clock, round(1e3/100), units="ns")
    cocotb.start_soon(clock.start())

    # reset
    dut.reset.value = 1
    await ClockCycles(dut.clock, 32)
    dut.reset.value = 0

    dut._log.info("begin test of icebreaker_top")

    # give the cpu some time to run
    await ClockCycles(dut.clock, 8 * 16)

    # check the ROM io output port (connected to `leds`)
    dut._log.info(dut.leds)
    assert dut.leds == 0xc
