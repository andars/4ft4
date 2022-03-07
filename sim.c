#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <unistd.h>

uint8_t hi(uint8_t in) {
    return (in >> 4);
}

uint8_t lo(uint8_t in) {
    return (in & 0xf);
}

int randomize_state = 0;
int print_ram = 0;

#define NUM_REGS_PER_RAM 4
#define RAM_REG_WIDTH 16 // each RAM reg is 16 4-bit characters
#define RAM_STATUS_PER_REG 4
#define RAM_SIZE (NUM_REGS_PER_RAM * RAM_REG_WIDTH)
#define NUM_RAMS 4
#define NUM_ROMS 2
#define NUM_PC_SLOTS 4

typedef struct {
    uint16_t pc_stack[NUM_PC_SLOTS];
    uint8_t stack_pointer;

    uint8_t accumulator;
    uint8_t carry;
    uint8_t registers[16];
    uint8_t address;

    uint8_t ram[NUM_RAMS * RAM_SIZE];
    uint8_t ram_status[NUM_RAMS * NUM_REGS_PER_RAM * RAM_STATUS_PER_REG];

    uint8_t ram_ports[NUM_RAMS];
    uint8_t rom_ports[NUM_ROMS];

    uint8_t test_signal;
} ProcessorState;

ProcessorState state;

typedef enum {
    INC,
    ADD,
    SUB,
    LD,
    XCH,
} AluOp;

uint16_t current_pc() {
    return state.pc_stack[state.stack_pointer];
}

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
    printf(" stack pointer: 0x%x\n", state.stack_pointer);
    for (int i = 0; i < NUM_PC_SLOTS; i++) {
        printf(" stack %d: 0x%x\n", i, state.pc_stack[i]);
    }
    printf(" carry: %d\n", state.carry);
    printf(" pc: 0x%x\n", current_pc());
    if (print_ram) {
        for (int ram = 0; ram < NUM_RAMS; ram++) {
            for (int reg = 0; reg < NUM_REGS_PER_RAM; reg++) {
                printf(" ram %d reg %d: ", ram, reg);
                for (int c = 0; c < RAM_REG_WIDTH; c++) {
                    printf("%x ", lo(state.ram[c + reg * RAM_REG_WIDTH + ram * RAM_SIZE]));
                }
                printf("\n");
            }
            printf(" ram %d port: 0x%1x\n", ram, state.ram_ports[ram]);
            printf("\n");
        }
    }
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

void push_stack() {
    state.stack_pointer = (state.stack_pointer + 1) % NUM_PC_SLOTS;
}

void pop_stack() {
    state.stack_pointer = (state.stack_pointer + NUM_PC_SLOTS - 1) % NUM_PC_SLOTS;
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
        uint8_t result = acc_in + lo(~reg_in) + ((~carry_in) & 0x1);

        acc_out = result & 0xf;
        carry_out = (result >> 4) & 0x1;
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
        uint8_t result = acc_in + lo(~0x1) + 0x1;

        acc_out = result & 0xf;
        carry_out = (result >> 4) & 0x1;
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
        exit(1);
    }

    state.accumulator = acc_out;
    state.carry = carry_out;
}

void load_accumulator(uint8_t inst) {
    uint8_t immediate = lo(inst);

    state.accumulator = immediate;
}

void fetch_immediate(uint8_t inst, uint8_t data) {
    uint8_t reg = lo(inst);
    printf("reg %d\n", reg);

    state.registers[reg] = hi(data);
    state.registers[reg + 1] = lo(data);
}

void jump_12(uint16_t target) {
    state.pc_stack[state.stack_pointer] = target;
}

void jump_unconditional(uint8_t inst, uint8_t second) {
    uint16_t target = (((uint16_t)lo(inst)) << 8) | second;

    jump_12(target);
}

void jump_8(uint8_t target) {
    uint16_t target_12 = (current_pc() & ~0xff) | target;
    jump_12(target_12);
}

void jump_indirect(uint8_t inst) {
    uint8_t reg = lo(inst) & ~0x1;

    uint8_t target_8 = (state.registers[reg] << 4) | state.registers[reg + 1];
    jump_8(target_8);
}

#define COND_TEST  (1 << 0)
#define COND_CARRY (1 << 1)
#define COND_ACC   (1 << 2)
#define COND_INV   (1 << 3)
void jump_conditional(uint8_t inst, uint8_t second) {
    uint8_t cond_spec = lo(inst);
    uint8_t target_8 = second;

    int take_branch = 0;

    if (cond_spec & COND_ACC) {
        take_branch = take_branch || (state.accumulator == 0);
    }
    if (cond_spec & COND_CARRY) {
        take_branch = take_branch || (state.carry == 1);
    }
    if (cond_spec & COND_TEST) {
        take_branch = take_branch || (state.test_signal == 1);
    }

    if (cond_spec & COND_INV) {
        take_branch = !take_branch;
    }

    if (take_branch) {
        jump_8(target_8);
    }
}

void increment_and_jump_if_zero(uint8_t inst, uint8_t target) {
    uint8_t reg = lo(inst);

    state.registers[reg] = lo(state.registers[reg] + 1);

    if (state.registers[reg] != 0) {
        jump_8(target);
    }
}

void call(uint8_t inst, uint8_t second) {
    uint16_t target = (((uint16_t)lo(inst)) << 8) | second;

    push_stack();
    jump_12(target);
}

void load_and_ret(uint8_t inst) {
    load_accumulator(inst);
    pop_stack();
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

void add_from_ram(void) {
    uint8_t value = lo(state.ram[state.address]);

    uint8_t result = state.accumulator + value + state.carry;

    state.carry = (result >> 4) & 0x1;
    state.accumulator = lo(result);
}

void sub_from_ram(void) {
    uint8_t value = lo(state.ram[state.address]);

    uint8_t result = state.accumulator + lo(~value) + ((~state.carry) & 0x1);

    // carry bit is set if the subtraction requires a borrow
    state.carry = (result >> 4) & 0x1;
    state.accumulator = lo(result);
}

void write_ram_port(void) {
    uint8_t selected_ram = (state.address >> 6);

    assert(selected_ram < NUM_RAMS);
    state.ram_ports[selected_ram] = state.accumulator;
}

void write_ram_status(uint8_t index) {
    uint8_t selected_ram_reg = hi(state.address);

    state.ram_status[RAM_STATUS_PER_REG * selected_ram_reg + index] = state.accumulator;
}

void read_ram_status(uint8_t index) {
    uint8_t selected_ram_reg = hi(state.address);

    state.accumulator = state.ram_status[RAM_STATUS_PER_REG * selected_ram_reg + index];
}

void write_rom_port(void) {
    uint8_t selected_rom = hi(state.address);

    assert(selected_rom < NUM_ROMS);
    state.rom_ports[selected_rom] = state.accumulator;
}

void read_rom_port(void) {
    uint8_t selected_rom = hi(state.address);

    assert(selected_rom < NUM_ROMS);
    state.accumulator = state.rom_ports[selected_rom];
}

uint8_t read_rom(FILE *in, uint16_t addr) {
    size_t count;
    uint8_t data = 0;

    fseek(in, addr, SEEK_SET);
    count = fread(&data, 1, 1, in);
    if (count == 0) {
        printf("failed to read rom at %d, returning 0\n", addr);
    }

    return data;
}

void fetch_indirect(FILE *in, uint8_t inst) {
    uint8_t reg = lo(inst);

    uint8_t src_addr_8 = (state.registers[0] << 4) | state.registers[1];
    uint16_t src_addr_12 = (current_pc() & ~0xff) | src_addr_8;

    uint8_t data = read_rom(in, src_addr_12);

    state.registers[reg] = hi(data);
    state.registers[reg+1] = lo(data);
}

int read_instruction(FILE *in, uint8_t *inst) {
    size_t count;

    fseek(in, current_pc(), SEEK_SET);

    count = fread(inst, 1, 1, in);

    if (count != 0) {
        state.pc_stack[state.stack_pointer]++;
    }

    return count;
}

int exec_instruction(FILE *in) {
    uint8_t inst, second;
    size_t count;

    fseek(in, current_pc(), SEEK_SET);

    count = read_instruction(in, &inst);
    if (count == 0) {
        // end of file, no instruction
        return 0;
    }

    size_t loc = ftell(in) - 1;
    printf("+0x%lx: 0x%x %d\n", loc, inst, inst);

    if (hi(inst) == 0x3) {
        if ((inst & 0x1) == 0) {
            printf("FIN\n");
            fetch_indirect(in, inst);
        } else {
            printf("JIN\n");
            jump_indirect(inst);
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
            //TODO(inst)
        } else {
            printf("unknown\n");
            exit(1);
        }
    } else if (hi(inst) == 0x2) {
        if ((inst & 0x1) == 0) {
            read_instruction(in, &second);
            printf("FIM\n");
            fetch_immediate(inst, second);
        } else {
            printf("SRC\n");
            set_address(inst);
        }
    } else if (hi(inst) == 0xd) {
        printf("LDM\n");
        load_accumulator(inst);
    } else if (hi(inst) == 0x4) {
        read_instruction(in, &second);
        printf("JUN\n");
        jump_unconditional(inst, second);
    } else if (hi(inst) == 0x1) {
        read_instruction(in, &second);
        printf("JCN\n");
        jump_conditional(inst, second);
    } else if (hi(inst) == 0x7) {
        read_instruction(in, &second);
        printf("ISZ\n");
        increment_and_jump_if_zero(inst, second);
    } else if (hi(inst) == 0x5) {
        read_instruction(in, &second);
        printf("JMS\n");
        call(inst, second);
    } else if (hi(inst) == 0xc) {
        printf("BBL\n");
        load_and_ret(inst);
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
            write_ram_port();
        } else if (code == 0x2) {
            printf("WRR\n");
            write_rom_port();
        } else if (code == 0x3) {
            printf("WPM\n");
            printf("unimplemented!\n");
            exit(1);
        } else if (0x4 <= code && code <= 0x7) {
            uint8_t index = code - 0x4;
            printf("WR%d\n", index);
            write_ram_status(index);
        } else if (code == 0x8) {
            printf("SBM\n");
            sub_from_ram();
        } else if (code == 0x9) {
            printf("RDM\n");
            read_ram();
        } else if (code == 0xa) {
            printf("RDR\n");
            read_rom_port();
        } else if (code == 0xb) {
            printf("ADM\n");
            add_from_ram();
        } else if (0xc <= code && code <= 0xf) {
            uint8_t index = code - 0xc;
            printf("RD%d\n", index);
            read_ram_status(index);
        }
    } else {
        printf("unknown\n");
        exit(1);
    }

    print_processor_state();

    return 1;
}

void print_usage() {
    printf("usage: ./sim [-r] [-c <cycle_count>] <binary>\n");
}

int main(int argc, char *argv[]) {
    printf("simulator\n");

    char *binary = NULL;

    if (argc < 2) {
        print_usage();
        return 1;
    }

    int opt;
    int cycles = -1;

    while ((opt = getopt(argc, argv, "rc:m")) != -1) {
        switch (opt) {
        case 'r':
            randomize_state = 1;
            break;
        case 'c':
            cycles = atoi(optarg);
            if (cycles == 0) {
                printf("cycle count must be positive\n");
                print_usage();
                return 1;
            }
            break;
        case 'm':
            print_ram = 1;
            break;
        default:
            printf("invalid option\n");
            print_usage();
            return 1;
        }
    }

    if (optind >= argc) {
        printf("missing binary name\n");
        print_usage();
        return 1;
    }

    binary = argv[optind];

    if (randomize_state) {
        randomize_processor_state();
    }

    init_ram();

    printf("loading %s\n", binary);

    FILE *input = fopen(binary, "rb");

    if (cycles < 0) {
        while (exec_instruction(input));
    } else {
        for (int i = 0; i < cycles; i++) {
            exec_instruction(input);
        }
    }

    printf("Finished.\n");
    print_processor_state();

    fclose(input);
}
