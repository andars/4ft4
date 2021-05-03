#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

uint8_t hi(uint8_t in) {
    return (in >> 4);
}

uint8_t lo(uint8_t in) {
    return (in & 0xf);
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

    printf("0x%lx: 0x%x %d\n", loc, inst, inst);

    if (hi(inst) == 0x3) {
        if ((inst & 0x1) == 0) {
            fread(&second, 1, 1, in);
            printf("FIN\n");
        }
    } else if (hi(inst) == 0x6) {
        printf("INC\n");
    } else if (hi(inst) == 0x8) {
        printf("ADD\n");
    } else if (hi(inst) == 0x9) {
        printf("SUB\n");
    } else if (hi(inst) == 0xa) {
        printf("LD\n");
    } else if (hi(inst) == 0xb) {
        printf("XCH\n");
    } else if (hi(inst) == 0xf) {
        // acc

        if (lo(inst) == 0x0) {
            printf("CLB\n");
        } else if (lo(inst) == 0x1) {
            printf("CLC\n");
        } else if (lo(inst) == 0x2) {
            printf("IAC\n");
        } else if (lo(inst) == 0x3) {
            printf("CMC\n");
        } else if (lo(inst) == 0x4) {
            printf("CMA\n");
        } else if (lo(inst) == 0x5) {
            printf("RAL\n");
        } else if (lo(inst) == 0x6) {
            printf("RAR\n");
        } else if (lo(inst) == 0x7) {
            printf("TCC\n");
        } else if (lo(inst) == 0x8) {
            printf("DAC\n");
        } else if (lo(inst) == 0x9) {
            printf("TCS\n");
        } else if (lo(inst) == 0xa) {
            printf("STC\n");
        } else if (lo(inst) == 0xb) {
            printf("DAA\n");
        } else if (lo(inst) == 0xc) {
            printf("KBP\n");
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
