#!/usr/bin/env python3
import sys
import struct

instructions = [
    # index register instructions
    ('0011PPP0', 'FIN', ['P']),
    ('0110RRRR', 'INC', ['R']),
    ('1000RRRR', 'ADD', ['R']),
    ('1001RRRR', 'SUB', ['R']),
    ('1010RRRR', 'LD',  ['R']),
    ('1011RRRR', 'XCH', ['R']),
    # accumulator instructions
    ('11110000', 'CLB'),
    ('11110001', 'CLC'),
    ('11110010', 'IAC'),
    ('11110011', 'CMC'),
    ('11110100', 'CMA'),
    ('11110101', 'RAL'),
    ('11110110', 'RAR'),
    ('11110111', 'TCC'),
    ('11111000', 'DAC'),
    ('11111001', 'TCS'),
    ('11111010', 'STC'),
    ('11111011', 'DAA'),
    ('11111100', 'KBP'),
    #('11111101', '')
    #('11111110', '')
    #('11111111', '')
    # immediate instructions
    ('0010PPP0', 'FIM', ['P', 'D'], 'DDDDDDDD'),
    ('1101DDDD', 'LDM', ['D']),
    # control instructions
    ('0100AAAA', 'JUN', ['A'], 'AAAAAAAA'),
    ('0011RRR1', 'JIN', ['R']),
    ('0001CCCC', 'JCN', ['C', 'A'], 'AAAAAAAA'),
    ('0111RRRR', 'ISZ', ['R', 'A'], 'AAAAAAAA'),
    # subroutine linkage instructions
    ('0101AAAA', 'JMS', ['A'], 'AAAAAAAA'),
    ('1100DDDD', 'BBL', ['D']),
    # nop
    ('00000000', 'NOP'),
    # memory selection
    ('11111101', 'DCL'),
    ('0010PPP1', 'SRC', ['P']),
    # i/o and RAM instructions
    ('11100000', 'WRM'),
    ('11100001', 'WMP'),
    ('11100010', 'WRR'),
    ('11100011', 'WPM'),
    ('11100100', 'WR0'),
    ('11100101', 'WR1'),
    ('11100110', 'WR2'),
    ('11100111', 'WR3'),
    ('11101000', 'SBM'),
    ('11101001', 'RDM'),
    ('11101010', 'RDR'),
    ('11101011', 'ADM'),
    ('11101100', 'RD0'),
    ('11101101', 'RD1'),
    ('11101110', 'RD2'),
    ('11101111', 'RD3'),
]

labels = {}

def str_to_mask(s, a):
    mask = 0
    base = 8
    for i in range(8):
        if s[7 - i] == a:
            mask = mask | (1 << i)
            base = min(base, i)
    return mask, base

def desc_to_bin(desc, values={}):
    fw_args = set()
    sw_args = set()
    inst_base = list(desc[0])
    fw_str = desc[0]

    # strip operand fields from instruction
    # and determine operand ids referenced
    # in the first word (in fw_args)
    for i in range(len(fw_str)):
        if fw_str[i] not in ['0', '1']:
            inst_base[i] = '0'
            fw_args.add(fw_str[i])

    if len(desc) > 3:
        # two-word instruction
        sw_str = desc[3]

        # determine operand ids referenced
        # in the second word (in sw_args)
        for i in range(len(sw_str)):
            sw_args.add(sw_str[i])

    sw_arg_layout = {}
    fw_arg_layout = {}

    # compute the mask and base for arguments
    # in the second instruction word
    for a in sw_args:
        mask, base = str_to_mask(desc[3], a)

        sw_arg_layout[a] = (mask, base)

    # compute the mask and base for arguments
    # in the first instruction word
    for a in fw_args:
        mask, base = str_to_mask(desc[0], a)

        shift = 0

        if a in sw_args:
            # arguments that are split over the first
            # and second instruction words have the
            # low bits in the second word
            shift = bin(sw_arg_layout[a][0]).count('1')

        fw_arg_layout[a] = (mask, base, shift)

    inst = int(''.join(inst_base), 2)

    for a in fw_args:
        mask, base, shift = fw_arg_layout[a]
        print("fw arg {} {:08b} {}".format(a, mask, base))
        #TODO: no default values
        #value = values[a]
        value = values.get(a, 0)
        part = ((value >> shift) << base) & mask
        print("part {:08b}".format(part))

        inst = inst | part

    if len(desc) > 3:
        inst_sw = 0

        # compute the second word for
        # two word instructions
        for a in sw_args:
            mask, base = sw_arg_layout[a]
            print("sw arg {} {:08b} {}".format(a, mask, base))
            #TODO: no default values
            #values = values[a]
            value = values.get(a, 0)
            part = (value << base) & mask
            print("part {:08b}".format(part))

            inst_sw = inst_sw | part


        print("inst: {:02x} {:02x} - {:08b} {:08b}".format(inst, inst_sw, inst, inst_sw))
        return inst, inst_sw
    else: 
        print("inst: {:02x} - {:08b}".format(inst, inst))
        return inst,

def get_desc_and_operands(inst):
    op = inst[0]
    desc = find_instruction(op)

    operand_count = len(inst) - 1
    expected = len(desc[2]) if len(desc) >= 3 else 0
    assert operand_count == expected

    operand_map = {}

    for i in range(operand_count):
        value = inst[i+1]
        name = desc[2][i]
        operand_map[name] = value

    return desc, operand_map

def inst_to_bin(inst):
    desc, operands = get_desc_and_operands(inst)

    return desc_to_bin(desc, operands)

def parse_value(f):
    print("reading ", f)
    if f[0:2] == '0x':
        v = int(f[2:], 16)
        print("hex -> {:02x} = {}".format(v,v))
    elif f[-1] == 'P':
        # register pair symbols
        v = int(f[0])
        assert 0 <= v and v <= 7
        print("pair -> ", v)
    elif f in labels:
        v = labels[f]
        print("label -> ", v)
    else:
        v = int(f)
        print("int -> ", v)
    return v

def assemble_line(line, loc=0):
    print("assembling line...")
    line = line.strip()
    inst_start = 0
    inst_end = len(line)
    if ',' in line:
        label_end = line.index(',')
        label = line[:label_end]
        inst_start = label_end + 1
        print("label ", label)
        labels[label] = loc
    if '/' in line:
        inst_end = line.index('/')
        comment = line[inst_end:]
        print("comment ", comment)

    inst = line[inst_start:inst_end].strip()
    print("instruction ", inst)

    fields = inst.split(' ')
    opcode = fields[0]
    operands = [parse_value(f) for f in fields[1:]]

    print("'{}'".format(opcode))

    if opcode:
        if opcode[0].isdigit():
            # constant data
            assert len(operands) == 0
            words = (parse_value(opcode),)
        else:
            words = inst_to_bin([opcode] + operands)
        print(['{:02x}'.format(s) for s in words])
        return words
    else:
        print("no opcode")
        return ()


def find_instruction(op):
    for inst in instructions:
        if inst[1] == op:
            return inst
    return None

def find_instruction_by_bin(inst):
    for desc in instructions:
        c = int(desc[0], 2)
        op_mask = desc_to_op_mask(desc)

with open('out.bin', 'wb') as f:
    for o in range(16):
        inst = o << 4
        f.write(struct.pack('<B', inst));

print("all instructions:")
for desc in instructions:
    print(desc[0], desc[1])
    desc_to_bin(desc)
    print()

print("test")
assert desc_to_bin(find_instruction('FIM'), {'P': 0, 'D': 255}) == (0x20, 0xff)
assert inst_to_bin(['FIM', 0, 255]) == (0x20, 0xff)
assert inst_to_bin(['JUN', 0x3e0]) == (0x43, 0xe0)
assert inst_to_bin(['ADD', 1]) == (0x81,)
assert inst_to_bin(['LDM', 3]) == (0xd3,)
assert inst_to_bin(['JUN', 0x362]) == (0x43, 0x62)
assert inst_to_bin(['FIM', 0, 4]) == (0x20, 0x04)
assert inst_to_bin(['JCN', 6, 0x302]) == (0x16, 0x02)
print("passed")

assemble_line('FOO, JCN 6 0x302 / comment')
assemble_line('FOO, 16 / comment')

print("demo")
desc_to_bin(find_instruction('JUN'), {'A': 0x3e0})
desc_to_bin(find_instruction('ADD'), {'R': 1})
desc_to_bin(find_instruction('LDM'), {'D': 3})
desc_to_bin(find_instruction('JUN'), {'A': 0x362})
desc_to_bin(find_instruction('FIM'), {'P': 0, 'D': 4})
desc_to_bin(find_instruction('JUN'), {'A': 0x370})

if len(sys.argv) > 1:
    out = []
    loc = 0
    labels = {}
    print("assembling ", sys.argv[1])
    with open(sys.argv[1], 'r') as f_in:
        for line in f_in.readlines():
            print(line.strip())
            words = assemble_line(line, loc)
            for w in words:
                out.append(w)
                loc += 1

    print(labels)
    for i in range(len(out)):
        w = out[i]
        print("{:04x}: {:02x}".format(i, w))

    if len(sys.argv) > 2:
        output_name = sys.argv[2]
    else:
        output_name = sys.argv[1][:sys.argv[1].rfind(".")] + ".bin"

    with open(output_name, 'wb') as f_out:
        print("writing {} bytes to {}".format(len(out), output_name))
        f_out.write(bytes(out))
