import sys
import re


OPCODES = {
    # ALU core
    "NOP":   0x00,  # 0000 0000
    "AND":   0x01,
    "OR":    0x02,
    "XOR":   0x03,
    "NOT":   0x04,
    "ADD":   0x05,
    "ADDU":  0x06,
    "ADDC":  0x07,
    "SUB":   0x09,
    "CMP":   0x0B,

    # shifts etc
    "ALSH":  0x82,
    "ARSH":  0x83,
    "LSH":   0x84,
    "RSH":   0x8C,

    # memory / control group (op=0100)
    "LOAD":     0x40,  # op=4, ext=0
    "STORE":    0x44,  # op=4, ext=4
    "STOREPC":  0x48,  # op=4, ext=8
    "J":        0x4C,  # op=4, ext=C  (Jcond Rtarget)

    # branch group (op=1100)
    "B":        0xC0,  # op=C, disp in low 8 bits
}


COND_CODES = {
    "EQ": 0b0000,
    "NE": 0b0001,
    "CS": 0b0010,
    "CC": 0b0011,
    "HI": 0b0100,
    "LS": 0b0101,
    "GT": 0b0110,
    "LE": 0b0111,
    "FS": 0b1000,
    "FC": 0b1001,
    "LO": 0b1010,
    "HS": 0b1011,
    "LT": 0b1100,
    "GE": 0b1101,
    "UC": 0b1110,  # unconditional
    "NV": 0b1111,  # never
}

IMM8_INSTRS = {
    "ADDI":   0x50,
    "ADDUI":  0x60,
    "ADDCI":  0x70,
    "SUBI":   0x90,
    "CMPI":   0xB0,
    "ANDI":   0x10,
    "ADDCUI": 0xD0,
}


REGS = {f"R{i}": i for i in range(16)}  # R0..R15
const_map  = {}

def parse_register(tok: str) -> int:
    tok = tok.strip().upper()
    if tok not in REGS:
        raise ValueError(f"Unknown register: {tok}")
    return REGS[tok]


def parse_immediate(tok: str) -> int:
    tok = tok.strip()

    if tok in const_map:
        return const_map[tok]

    # support decimal, hex like 0x10, or binary like 0b1010
    if tok.startswith("0x") or tok.startswith("0X"):
        return int(tok, 16)
    if tok.startswith("0b") or tok.startswith("0B"):
        return int(tok, 2)
    return int(tok, 10)


def clean_line(line: str) -> str:
    # strip comments starting with ';'
    line = line.split('#', 1)[0]
    return line.strip()


def tokenize_line(line: str):
    # split on spaces and commas
    # e.g. "ADD R1, R2, R3" -> ["ADD", "R1", "R2", "R3"]
    parts = re.split(r"[,\s]+", line)
    return [p for p in parts if p]


def first_pass(lines):
    """
    Return (instructions, label_map)
    instructions: list of (original_line, tokens, line_number, pc)
    label_map: dict name -> pc
    """
    label_map = {}
    instructions = []
    pc = 0  # instruction index, one word per instruction

    for lineno, raw_line in enumerate(lines, start=1):
        line = clean_line(raw_line)
        if not line:
            continue
        
        if "=" in line:
            name, value = line.split("=", 1)
            name  = name.strip()
            value = value.strip()
            const_map[name] = parse_immediate(value)
            continue


        # label line: "foo:" or "foo: ADD R1, R2, R3"
        if ":" in line:
            label, *rest = line.split(":", 1)
            label_name = label.strip()
            if not label_name.isidentifier():
                raise ValueError(f"Invalid label name '{label_name}' on line {lineno}")
            if label_name in label_map:
                raise ValueError(f"Duplicate label '{label_name}' on line {lineno}")
            label_map[label_name] = pc

            # anything after colon is an instruction on same line
            after = rest[0].strip()
            if after:
                tokens = tokenize_line(after)
                instructions.append((after, tokens, lineno, pc))
                pc += 1
        else:
            tokens = tokenize_line(line)
            instructions.append((line, tokens, lineno, pc))
            pc += 1

    return instructions, label_map



def encode_instruction(tokens, labels, pc):
    mnemonic = tokens[0].upper()


    # immediate group first
    if mnemonic in IMM8_INSTRS:
        opcode = IMM8_INSTRS[mnemonic]
        opcode_high = (opcode >> 4) & 0xF

        if len(tokens) != 3:
            raise ValueError(f"{mnemonic} expects 2 operands: Rd, imm")

        rd = parse_register(tokens[1])
        imm = parse_immediate(tokens[2]) & 0xFF

        word = (opcode_high << 12) | (rd << 8) | imm
        return word & 0xFFFF

    # ---- branch / jump pseudo-mnemonics ----
    # Map BEQ label -> B cond=EQ, etc.
    if mnemonic.startswith("B") and mnemonic != "B":
        # e.g. "BEQ" -> cond "EQ"
        cond_name = mnemonic[1:]  # drop leading 'B'
        if cond_name not in COND_CODES:
            raise ValueError(f"Unknown branch condition in {mnemonic}")
        base_mnemonic = "B"
        cond = COND_CODES[cond_name]
        if len(tokens) != 2:
            raise ValueError(f"{mnemonic} expects 1 operand: label")
        label = tokens[1]
        return encode_branch(base_mnemonic, cond, label, labels, pc)

    if mnemonic.startswith("J") and mnemonic not in ("J", "JMP"):
        # e.g. "JEQ R3" -> J cond=EQ, Rtarget=R3
        cond_name = mnemonic[1:]  # drop leading 'J'
        if cond_name not in COND_CODES:
            raise ValueError(f"Unknown jump condition in {mnemonic}")
        base_mnemonic = "J"
        cond = COND_CODES[cond_name]
        if len(tokens) != 2:
            raise ValueError(f"{mnemonic} expects 1 operand: Rtarget")
        rtarget = parse_register(tokens[1])
        return encode_jump(base_mnemonic, cond, rtarget)

    # Handle plain unconditional B / J as cond=UC
    if mnemonic == "B":
        if len(tokens) != 2:
            raise ValueError("B expects 1 operand: label")
        return encode_branch("B", COND_CODES["UC"], tokens[1], labels, pc)

    if mnemonic in ("J", "JMP"):
        # J Rn  or JMP Rn  (unconditional)
        if len(tokens) != 2:
            raise ValueError("J expects 1 operand: Rtarget")
        rtarget = parse_register(tokens[1])
        return encode_jump("J", COND_CODES["UC"], rtarget)

    # ---- "real" opcodes ----
    if mnemonic not in OPCODES:
        raise ValueError(f"Unknown instruction: {mnemonic}")

    opcode = OPCODES[mnemonic]
    opcode_high = (opcode >> 4) & 0xF
    opcode_low  = opcode & 0xF

    # defaults
    rd = 0
    rs = 0

    # ALU register-register
    if mnemonic in ("ADD", "ADDU", "ADDC", "SUB", "CMP",
                    "AND", "OR", "XOR", "NOT",
                    "ALSH", "ARSH", "LSH", "RSH",
                    "NOP"):
        # NOP can just be rd=rs=0
        if mnemonic != "NOP":
            if len(tokens) != 3:
                raise ValueError(f"{mnemonic} expects 2 operands: rd, rs")
            rd = parse_register(tokens[1])
            rs = parse_register(tokens[2])
        word = (opcode_high << 12) | (rd << 8) | (opcode_low << 4) | rs

    # LOAD Rd, [Rs]
    elif mnemonic == "LOAD":
        if len(tokens) != 3:
            raise ValueError("LOAD expects 2 operands: Rd, [Rs]")
        rd = parse_register(tokens[1])
        addr_tok = tokens[2]
        if not (addr_tok.startswith("[") and addr_tok.endswith("]")):
            raise ValueError("LOAD second operand must be [Rs]")
        rs = parse_register(addr_tok[1:-1])
        word = (opcode_high << 12) | (rd << 8) | (opcode_low << 4) | rs

    # STORE Rs, [Rd]
    elif mnemonic == "STORE":
        if len(tokens) != 3:
            raise ValueError("STORE expects 2 operands: Rs, [Rd]")
        rs = parse_register(tokens[1])
        addr_tok = tokens[2]
        if not (addr_tok.startswith("[") and addr_tok.endswith("]")):
            raise ValueError("STORE second operand must be [Rd]")
        rd = parse_register(addr_tok[1:-1])
        word = (opcode_high << 12) | (rd << 8) | (opcode_low << 4) | rs

    # STOREPC Rd   (store current PC in Rd)
    elif mnemonic == "STOREPC":
        if len(tokens) != 2:
            raise ValueError("STOREPC expects 1 operand: Rd")
        rd = parse_register(tokens[1])
        rs = 0  # unused
        word = (opcode_high << 12) | (rd << 8) | (opcode_low << 4) | rs

    else:
        raise ValueError(f"Encoding not implemented for {mnemonic}")

    return word & 0xFFFF


def encode_branch(base_mnemonic, cond, target_tok, labels, pc):
    opcode = OPCODES[base_mnemonic]
    opcode_high = (opcode >> 4) & 0xF  # should be 0xC for branch

    # Decide: is the target a label or a numeric immediate?
    if target_tok in labels:
        target_pc = labels[target_tok]
        offset = target_pc - (pc + 1)       # PC-relative
    else:
        # raw immediate displacement
        offset = parse_immediate(target_tok)

    # require it to fit in signed 8-bit
    if offset < -128 or offset > 127:
        raise ValueError(f"Branch offset out of range: {offset}")

    offset &= 0xFF  # keep low 8 bits

    # Format: [opcode_high][cond][offset[7:0]]
    word = (opcode_high << 12) | (cond << 8) | offset
    return word & 0xFFFF



def encode_jump(base_mnemonic, cond, rtarget):
    opcode = OPCODES[base_mnemonic]
    opcode_high = (opcode >> 4) & 0xF  # 0x4
    opcode_low  = opcode & 0xF         # 0xC (ext=1100)

    # Format: [op][cond][ext=opcode_low][Rtarget]
    word = (opcode_high << 12) | (cond << 8) | (opcode_low << 4) | rtarget
    return word & 0xFFFF



def assemble(source_lines):
    instructions, labels = first_pass(source_lines)
    machine_words = []

    for (line, tokens, lineno, pc) in instructions:
        try:
            word = encode_instruction(tokens, labels, pc)
        except Exception as e:
            raise RuntimeError(f"Error on line {lineno} ('{line}'): {e}")
        machine_words.append(word)

    return machine_words


def write_hex(words, filename):
    with open(filename, "w") as f:
        for w in words:
            f.write(f"{w:04X}\n")


def main():
    if len(sys.argv) != 3:
        print("Usage: python assembler.py input.asm output.hex")
        sys.exit(1)

    in_file = sys.argv[1]
    out_file = sys.argv[2]

    with open(in_file, "r") as f:
        lines = f.readlines()

    words = assemble(lines)
    write_hex(words, out_file)
    print(f"Wrote {len(words)} words to {out_file}")


if __name__ == "__main__":
    main()
