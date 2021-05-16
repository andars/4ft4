#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

uint8_t hi(uint8_t in) {
    return (in >> 4);
}

uint8_t lo(uint8_t in) {
    return (in & 0xf);
}

void exec_fin() {

}

int randomize_state = 0;

#define RAM_SIZE (4 * 16)
#define NUM_RAMS 4

typedef struct {
    uint8_t accumulator;
    uint8_t carry;
    uint8_t registers[16];
    uint8_t address;

    uint8_t ram[NUM_RAMS * RAM_SIZE];
} ProcessorState;

ProcessorState state;

typedef enum {
    INC,
    ADD,
    SUB,
    LD,
    XCH,
} AluOp;

void print_processor_state() {
    printf("---\n");
    printf("Current state:\n");
    printf(" accumulator: 0x%x\n", state.accumulator);
    for (int i = 0; i < 16; i+=2) {
        printf(" register %2d: 0x%x", i, state.registers[i]);
        printf(" |");
        printf(" register %2d: 0x%x", i + 1, state.registers[i + 1]);
        printf(" - %dP : 0x%02x\n", i/2, (state.registers[i] << 4) | state.registers[i+1]);
    }
    printf(" carry: %d\n", state.carry);
    printf("---\n");
}

void randomize_processor_state() {
    state.accumulator = lo(rand());
    for (int i = 0; i < 16; i++) {
        state.registers[i] = lo(rand());
    }
    state.address = lo(rand());
    state.carry = rand() % 2;
}

void init_ram() {
    state.ram[0] = 1;

    state.ram[16] = 3;
}

void exec_alu_inst(uint8_t inst, AluOp op) {
    printf("ALU: 0x%x, %d\n", inst, op);

    const uint8_t r = inst & 0xf;

    const uint8_t carry_in = state.carry;
    const uint8_t reg_in = state.registers[r];
    const uint8_t acc_in = state.accumulator;

    uint8_t carry_out = carry_in;
    uint8_t reg_out = reg_in;
    uint8_t acc_out = acc_in;

    if (op == INC) {
        reg_out = (reg_in + 1) & 0xf;
    } else if (op == ADD) {
        uint8_t result = acc_in + reg_in + carry_in;

        acc_out = result & 0xf;
        carry_out = (result >> 4) & 0x1;
    } else if (op == SUB) {
        uint8_t result = acc_in - reg_in - carry_in;

        acc_out = result & 0xf;

        // TODO: carry_out
    } else if (op == LD) {
        acc_out = reg_in;
    } else if (op == XCH) {
        acc_out = reg_in;
        reg_out = acc_in;
    }

    state.carry = carry_out;
    state.registers[r] = reg_out;
    state.accumulator = acc_out;
}

void exec_acc_inst(uint8_t inst) {
    const uint8_t acc_in = state.accumulator;
    const uint8_t carry_in = state.carry;

    uint8_t carry_out = carry_in;
    uint8_t acc_out = acc_in;

    if (lo(inst) == 0x0) {
        printf("CLB\n");

        carry_out = 0;
        acc_out = 0;
    } else if (lo(inst) == 0x1) {
        printf("CLC\n");

        carry_out = 0;
    } else if (lo(inst) == 0x2) {
        printf("IAC\n");

        uint8_t result = acc_in + 1;
        acc_out = result & 0xf;
        carry_out = (result >> 4) & 0x1;
    } else if (lo(inst) == 0x3) {
        printf("CMC\n");

        carry_out = (~carry_in) & 0x1;
    } else if (lo(inst) == 0x4) {
        printf("CMA\n");

        acc_out = (~acc_in) & 0xf;
    } else if (lo(inst) == 0x5) {
        printf("RAL\n");

        uint8_t result = (acc_in << 1) | carry_in;

        acc_out = result & 0xf;
        carry_out = (result >> 4) & 0x1;
    } else if (lo(inst) == 0x6) {
        printf("RAR\n");

        carry_out = acc_in & 0x1;
        acc_out = (acc_in >> 1) | (carry_in << 3);
    } else if (lo(inst) == 0x7) {
        printf("TCC\n");

        acc_out = carry_in;
        carry_out = 0x0;
    } else if (lo(inst) == 0x8) {
        printf("DAC\n");

        acc_out = (acc_in - 1) & 0xf;
    } else if (lo(inst) == 0x9) {
        printf("TCS\n");

        if (carry_in) {
            acc_out = 10;
        } else {
            acc_out = 9;
        }

        carry_out = 0;


    } else if (lo(inst) == 0xa) {
        printf("STC\n");

        carry_out = 1;
    } else if (lo(inst) == 0xb) {
        printf("DAA\n");

        if ((acc_in > 9) || carry_in) {
            uint8_t result = (acc_in + 6);
            acc_out = result & 0xf;

            if ((result >> 4) & 0x1) {
                carry_out = 1;
            }

        }
    } else if (lo(inst) == 0xc) {
        printf("KBP\n");

        if (acc_in == 0x0) {
            acc_out = 0x0;
        } else if (acc_in == 0x1) {
            acc_out = 1;
        } else if (acc_in == 0x2) {
            acc_out = 2;
        } else if (acc_in == 0x4) {
            acc_out = 3;
        } else if (acc_in == 0x8) {
            acc_out = 4;
        } else {
            acc_out = 0xf;
        }
    } else {
        assert(0);
    }

    state.accumulator = acc_out;
    state.carry = carry_out;
}

void fetch_immediate(uint8_t inst, uint8_t data) {
    uint8_t reg = lo(inst);
    printf("reg %d\n", reg);

    state.registers[reg] = hi(data);
    state.registers[reg + 1] = lo(data);
}

void set_address(uint8_t inst) {
    uint8_t reg = lo(inst) & ~0x1;
    printf("reg %d\n", reg);

    // TODO: this also sends the address to the ROMs and RAMs. should
    // those be simulated separately, or just simulate the entire system
    // together?

    uint8_t address = (state.registers[reg] << 4) | state.registers[reg + 1];
    state.address = address;
}

void read_ram(void) {
    uint8_t value = lo(state.ram[state.address]);

    printf("read 0x%x from 0x%x\n", value, state.address);

    state.accumulator = value;
}

void write_ram(void) {
    uint8_t value = state.accumulator;

    printf("write 0x%x to 0x%x\n", value, state.address);

    state.ram[state.address] = value;
}

void add_ram(void) {
    uint8_t value = lo(state.ram[state.address]);

    uint8_t result = state.accumulator + value + state.carry;

    state.carry = (result >> 4) & 0x1;
    state.accumulator = lo(result);
}

int exec_instruction(FILE *in) {
    uint8_t inst, second;
    size_t loc = ftell(in);
    size_t count;

    count = fread(&inst, 1, 1, in);
    if (count == 0) {
        // end of file, no instruction
        return 0;
    }

    printf("+0x%lx: 0x%x %d\n", loc, inst, inst);

    if (hi(inst) == 0x3) {
        if ((inst & 0x1) == 0) {
            fread(&second, 1, 1, in);
            printf("FIN\n");
        }
    } else if (hi(inst) == 0x6) {
        printf("INC\n");
        exec_alu_inst(inst, INC);
    } else if (hi(inst) == 0x8) {
        printf("ADD\n");
        exec_alu_inst(inst, ADD);
    } else if (hi(inst) == 0x9) {
        printf("SUB\n");
        exec_alu_inst(inst, SUB);
    } else if (hi(inst) == 0xa) {
        printf("LD\n");
        exec_alu_inst(inst, LD);
    } else if (hi(inst) == 0xb) {
        printf("XCH\n");
        exec_alu_inst(inst, XCH);
    } else if (hi(inst) == 0xf) {
        // acc
        if (0x0 <= lo(inst) && lo(inst) <= 0xc) {
            exec_acc_inst(inst);
        } else if (lo(inst) == 0xd) {
            printf("DCL\n");
        } else {
            printf("unknown\n");
            exit(1);
        }
    } else if (hi(inst) == 0x2) {
        if ((inst & 0x1) == 0) {
            fread(&second, 1, 1, in);
            printf("FIM\n");
            fetch_immediate(inst, second);
        } else {
            printf("SRC\n");
            set_address(inst);
        }
    } else if (hi(inst) == 0xd) {
        printf("LDM\n");
    } else if (hi(inst) == 0x4) {
        fread(&second, 1, 1, in);
        printf("JUN\n");
    } else if (hi(inst) == 0x3) {
        printf("JIN\n");
    } else if (hi(inst) == 0x1) {
        fread(&second, 1, 1, in);
        printf("JCN\n");
    } else if (hi(inst) == 0x7) {
        fread(&second, 1, 1, in);
        printf("ISZ\n");
    } else if (hi(inst) == 0x5) {
        fread(&second, 1, 1, in);
        printf("JMS\n");
    } else if (hi(inst) == 0xc) {
        printf("BBL\n");
    } else if (hi(inst) == 0x0) {
        if (lo(inst) == 0x0) {
            printf("NOP\n");
        } else {
            printf("unknown\n");
            exit(1);
        }
    } else if (hi(inst) == 0xe) {
        uint8_t code = lo(inst);

        if (code == 0x0) {
            printf("WRM\n");
            write_ram();
        } else if (code == 0x1) {
            printf("WMP\n");
        } else if (code == 0x2) {
            printf("WRR\n");
        } else if (code == 0x3) {
            printf("WPM\n");
        } else if (0x4 <= code && code <= 0x7) {
            uint8_t index = code - 0x4;
            printf("WR%d\n", index);
        } else if (code == 0x8) {
            printf("SBM\n");
        } else if (code == 0x9) {
            printf("RDM\n");
            read_ram();
        } else if (code == 0xa) {
            printf("RDR\n");
        } else if (code == 0xb) {
            printf("ADM\n");
            add_ram();
        } else if (0xc <= code && code <= 0xf) {
            uint8_t index = code - 0xc;
            printf("RD%d\n", index);
        }
    } else {
        printf("unknown\n");
        exit(1);
    }

    print_processor_state();


    return 1;
}

int main(int argc, char *argv[]) {
    printf("simulator\n");

    char *binary = NULL;

    if (argc < 2) {
        printf("usage: ./sim <binary>\n");
        return 1;
    }

    for (int i = 1; i < argc; i++) {
        char *arg = argv[i];
        if (strcmp(arg, "-r") == 0) {
            randomize_state = 1;
        } else if (!binary) {
            binary = arg;
        } else {
            printf("invalid arguments\n");
            return 1;
        }
    }

    if (randomize_state) {
        randomize_processor_state();
    }

    init_ram();

    printf("loading %s\n", binary);

    FILE *input = fopen(binary, "rb");

    while (exec_instruction(input));

    fclose(input);
}
