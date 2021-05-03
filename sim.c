#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>

uint8_t hi(uint8_t in) {
    return (in >> 4);
}

uint8_t lo(uint8_t in) {
    return (in & 0xf);
}

void exec_fin() {

}

typedef struct {
    uint8_t accumulator;
    uint8_t carry;
    uint8_t registers[16];
} ProcessorState;

ProcessorState state;

typedef enum {
    INC,
    ADD,
    SUB,
    LD,
    XCH,
} AluOp;

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
        } else {
            printf("SRC\n");
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
        } else if (code == 0xa) {
            printf("RDR\n");
        } else if (code == 0xb) {
            printf("ADM\n");
        } else if (0xc <= code && code <= 0xf) {
            uint8_t index = code - 0xc;
            printf("RD%d\n", index);
        }
    } else {
        printf("unknown\n");
        exit(1);
    }


    return 1;
}

int main(int argc, char *argv[]) {
    printf("simulator\n");

    if (argc < 2) {
        printf("usage: ./sim <binary>\n");
        return 1;
    }

    printf("loading %s\n", argv[1]);

    FILE *input = fopen(argv[1], "rb");

    while (exec_instruction(input));

    fclose(input);
}
