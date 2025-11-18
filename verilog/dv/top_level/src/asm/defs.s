; Opcodes
OPCODE_ADD = 0x0`6
OPCODE_ADDI = 0x1`6
OPCODE_SUB = 0x2`6
OPCODE_MUL = 0x3`6
OPCODE_MULI = 0x4`6
OPCODE_AND = 0x5`6
OPCODE_ANDI = 0x6`6
OPCODE_OR = 0x7`6
OPCODE_ORI = 0x8`6
OPCODE_XOR = 0x9`6
OPCODE_XORI = 0xA`6
OPCODE_SLL = 0xB`6
OPCODE_SRL = 0xC`6
OPCODE_SRA = 0xD`6
OPCODE_LUI = 0xE`6
OPCODE_LLI = 0xF`6
OPCODE_OUT = 0x10`6
OPCODE_MAC = 0x11`6
OPCODE_MACCL = 0x12`6
OPCODE_MACRD = 0x13`6
OPCODE_SPEQ = 0x14`6
OPCODE_SPLT = 0x15`6
OPCODE_CLRP = 0x16`6
OPCODE_SPR = 0x17`6
OPCODE_SREQ = 0x18`6
OPCODE_SRLT = 0x19`6
OPCODE_LW = 0x1A`6
OPCODE_SW = 0x1B`6
OPCODE_SB = 0x1C`6
OPCODE_LWV = 0x1D`6
OPCODE_SWV = 0x1E`6
OPCODE_SBV = 0x1F`6
OPCODE_JUMP = 0x20`6
OPCODE_HALT = 0x21`6


; Registers and Immediates
#subruledef srcreg {
    $r{n: u6} => {
        assert(n < 64)
        (0 + n)`6
    }
    $g{n: u6} => { ; Global register notation
        assert(n < 48)
        (16 + n)`6
    }

    ; Special register names
    $tid => 0`6
    $at  => 15`6
}

#subruledef destreg {
    $r{n: u4} => {
        assert(n < 16)
        (0 + n)`4
    }

    ; Special register names
    $tid => 0`4
    $at  => 15`4
}

; Predicate bits, used as arguments to speq, splt, clrp
#subruledef predicate_bit {
    $p{n: u2} => {
      assert(n < 3)
      (1 << n)`4 ; Pad to 4-bit field
    }
}

; Instruction predicate rule
#subruledef predicate {
    ; Hack: Having the 0b (0b[pred]) before every
    ; instruction is a little messy, and bashing three
    ; one-bit params next to each other results in (0 0 0)
    ; (also ugly). Just enumerate everything.
    () => 0`3
    (000) => 0`3
    (001) => 1`3
    (010) => 2`3
    (011) => 3`3
    (100) => 4`3
    (101) => 5`3
    (110) => 6`3
    (111) => 7`3
}

; Immediates
#subruledef immediate13 {
    ; Autodetect integer or fixed point:
    ; 1 -> integer, 1. or 1.0 or 1.11123 or 2/135 -> fixed point.
    {n: s13}         => n
    {i: s3}.         => i @ 0`10

    ; customasm doesn't have if conditions, floats, or string processing
    ; so we can't get leading/trailing zeros on the fractional portion.
    ; Instead, just force the user to pad decimals to 6 places.
    {i: s3}.{f: i32} => {
        assert(f < 1000000)
        frac = (f * (1 << 10)) / 1000000
        i @ frac`10
    }

    {n: s32}/{d: s32} => {
        int = n / d
        frac = ((n * (1 << 10)) / d) - (int * (1 << 10))
        int`3 @ frac`10
    }
}

#subruledef immediate16 {
    ; Same as above but with a 6 bit integer part.
    ; 1 -> integer, 1. or 1.0 or 1.11123 or 2/135 -> fixed point.
    {n: s16}         => n
    {i: s6}.         => i @ 0`10

    ; customasm doesn't have if conditions, floats, or string processing
    ; so we can't get leading/trailing zeros on the fractional portion.
    ; Instead, just force the user to pad decimals to 6 places.
    {i: s6}.{f: i32} => {
        assert(f < 1000000)
        frac = (f * (1 << 10)) / 1000000
        i @ frac`10
    }

    {n: s32}/{d: s32} => {
        int = n / d
        frac = ((n * (1 << 10)) / d) - (int * (1 << 10))
        int`6 @ frac`10
    }
}

#subruledef immediate32 {
    ; Same as above but with the full integer part.
    {n: s32}         => n
    {i: s22}.         => i @ 0`10

    {i: s22}.{f: i32} => {
        assert(f < 1000000)
        frac = (f * (1 << 10)) / 1000000
        i @ frac`10
    }

    {n: s32}/{d: s32} => {
        int = n / d
        frac = ((n * (1 << 10)) / d) - (int * (1 << 10))
        int`22 @ frac`10
    }
}

#subruledef jumpoffset {
    ; customasm uses absolute label addresses,
    ; turn them into PC-relative addresses.
    {absolute: s23} => {
        relative = absolute - $ - 4
        relative`23
    }
}


; Base Instructions
#ruledef instructions {
    ; Basic math
    {pred: predicate} add     {rd: destreg}, {rs1: srcreg}, {rs2: srcreg}       => OPCODE_ADD   @ pred @ rd @ rs1 @ rs2 @ 0`7
    {pred: predicate} addi    {rd: destreg}, {rs1: srcreg}, {imm: immediate13}  => OPCODE_ADDI  @ pred @ rd @ rs1 @ imm
    {pred: predicate} sub     {rd: destreg}, {rs1: srcreg}, {rs2: srcreg}       => OPCODE_SUB   @ pred @ rd @ rs1 @ rs2 @ 0`7
    {pred: predicate} mul     {rd: destreg}, {rs1: srcreg}, {rs2: srcreg}       => OPCODE_MUL   @ pred @ rd @ rs1 @ rs2 @ 0`7
    {pred: predicate} muli    {rd: destreg}, {rs1: srcreg}, {imm: immediate13}  => OPCODE_MULI  @ pred @ rd @ rs1 @ imm
    {pred: predicate} and     {rd: destreg}, {rs1: srcreg}, {rs2: srcreg}       => OPCODE_AND   @ pred @ rd @ rs1 @ rs2 @ 0`7
    {pred: predicate} andi    {rd: destreg}, {rs1: srcreg}, {imm: immediate13}  => OPCODE_ANDI  @ pred @ rd @ rs1 @ imm
    {pred: predicate} or      {rd: destreg}, {rs1: srcreg}, {rs2: srcreg}       => OPCODE_OR    @ pred @ rd @ rs1 @ rs2 @ 0`7
    {pred: predicate} ori     {rd: destreg}, {rs1: srcreg}, {imm: immediate13}  => OPCODE_ORI   @ pred @ rd @ rs1 @ imm
    {pred: predicate} xor     {rd: destreg}, {rs1: srcreg}, {rs2: srcreg}       => OPCODE_XOR   @ pred @ rd @ rs1 @ rs2 @ 0`7
    {pred: predicate} xori    {rd: destreg}, {rs1: srcreg}, {imm: immediate13}  => OPCODE_XORI  @ pred @ rd @ rs1 @ imm
    {pred: predicate} sll     {rd: destreg}, {rs1: srcreg}, {shift: u5}         => OPCODE_SLL   @ pred @ rd @ rs1 @ 0`8 @ shift
    {pred: predicate} srl     {rd: destreg}, {rs1: srcreg}, {shift: u5}         => OPCODE_SRL   @ pred @ rd @ rs1 @ 0`8 @ shift
    {pred: predicate} sra     {rd: destreg}, {rs1: srcreg}, {shift: u5}         => OPCODE_SRA   @ pred @ rd @ rs1 @ 0`8 @ shift
    {pred: predicate} out     {rs: srcreg}                                      => OPCODE_OUT   @ pred @ 0`4 @ rs @ 0`13

    ; Load immediate
    {pred: predicate} lui     {rd: destreg}, {imm: immediate16} -> OPCODE_LUI @ pred @ rd @ 0`3 @ imm
    {pred: predicate} lli     {rd: destreg}, {imm: immediate16} -> OPCODE_LLI @ pred @ rd @ 0`3 @ imm

    ; MAC
    {pred: predicate} mac     {rs1: srcreg}, {rs2: srcreg}  => OPCODE_MAC   @ pred @ 0`4 @ rs1 @ rs2 @ 0`7
    {pred: predicate} maccl                                 => OPCODE_MACCL @ pred @ 0`23
    {pred: predicate} macrd   {rd: destreg}                 => OPCODE_MACRD @ pred @ rd @ 0`19

    ; Branching and Predication
    {pred: predicate} speq    {pred_data: predicate_bit}, {rs1: srcreg}, {rs2: srcreg}  => OPCODE_SPEQ  @ pred @ pred_data @ rs1 @ rs2 @ 0`7
    {pred: predicate} splt    {pred_data: predicate_bit}, {rs1: srcreg}, {rs2: srcreg}  => OPCODE_SPLT  @ pred @ pred_data @ rs1 @ rs2 @ 0`7
    {pred: predicate} clrp    {pred_data: predicate}                                    => OPCODE_CLRP  @ pred @ 0`1 @ pred_data @ 0`19
    {pred: predicate} spr     {rd: destreg}                                             => OPCODE_SPR   @ pred @ rd @ 0`19
    {pred: predicate} sreq    {rd: destreg}, {rs1: srcreg}, {rs2: srcreg}               => OPCODE_SREQ  @ pred @ rd @ rs1 @ rs2 @ 0`7
    {pred: predicate} srlt    {rd: destreg}, {rs1: srcreg}, {rs2: srcreg}               => OPCODE_SRLT  @ pred @ rd @ rs1 @ rs2 @ 0`7

    ; Memory
    {pred: predicate} lw      {rd: destreg}, {imm: immediate13}[{roff: srcreg}] => OPCODE_LW   @ pred @ rd @ roff @ imm
    {pred: predicate} sw      {rs: destreg}, {imm: immediate13}[{roff: srcreg}] => OPCODE_SW   @ pred @ rs @ roff @ imm
    {pred: predicate} sb      {rs: destreg}, {imm: immediate13}[{roff: srcreg}] => OPCODE_SB   @ pred @ rs @ roff @ imm
    {pred: predicate} lwv     {rd: destreg}, {imm: immediate13}[{roff: srcreg}] => OPCODE_LWV  @ pred @ rd @ roff @ imm
    {pred: predicate} swv     {rs: destreg}, {imm: immediate13}[{roff: srcreg}] => OPCODE_SWV  @ pred @ rs @ roff @ imm
    {pred: predicate} sbv     {rs: destreg}, {imm: immediate13}[{roff: srcreg}] => OPCODE_SBV  @ pred @ rs @ roff @ imm

    ; Jump
    {pred: predicate} jump    {offset: jumpoffset} => OPCODE_JUMP @ pred @ offset

    ; Halt
    halt => OPCODE_HALT @ 0`26
}


; Pseudoinstructions
#ruledef pseudoinstructions {
    ; Linalg
    {pred: predicate} dot4 {vector1: srcreg}, {vector2: srcreg} => asm{
        {pred} maccl
        {pred} mac {vector1} + 0, {vector2} + 0
        {pred} mac {vector1} + 1, {vector2} + 1
        {pred} mac {vector1} + 2, {vector2} + 2
        {pred} mac {vector1} + 3, {vector2} + 3
    }
    {pred: predicate} dot3 {vector1: srcreg}, {vector2: srcreg} => asm{
        {pred} maccl
        {pred} mac {vector1} + 0, {vector2} + 0
        {pred} mac {vector1} + 1, {vector2} + 1
        {pred} mac {vector1} + 2, {vector2} + 2
    }
    {pred: predicate} cross3 {vecdest: destreg}, {vector1: srcreg}, {vector2: srcreg} => asm{
        ; v[0] = a[1] * b[2] - a[2] * b[1];
        {pred} mul {vecdest} + 0, {vector1} + 1, {vector2} + 2
        {pred} mul           $at, {vector1} + 2, {vector2} + 1
        {pred} sub {vecdest} + 0, {vecdest} + 0, $at

        ; v[1] = a[2] * b[0] - a[0] * b[2];
        {pred} mul {vecdest} + 1, {vector1} + 2, {vector2} + 0
        {pred} mul           $at, {vector1} + 0, {vector2} + 2
        {pred} sub {vecdest} + 1, {vecdest} + 1, $at

        ; v[2] = a[0] * b[1] - a[1] * b[0];
        {pred} mul {vecdest} + 2, {vector1} + 0, {vector2} + 1
        {pred} mul           $at, {vector1} + 1, {vector2} + 0
        {pred} sub {vecdest} + 2, {vecdest} + 2, $at
    }
    {pred: predicate} addv4 {vecdest: destreg}, {vector1: srcreg}, {vector2: srcreg} => asm{
        {pred} add {vecdest} + 0, {vector1} + 0, {vector2} + 0
        {pred} add {vecdest} + 1, {vector1} + 1, {vector2} + 1
        {pred} add {vecdest} + 2, {vector1} + 2, {vector2} + 2
        {pred} add {vecdest} + 3, {vector1} + 3, {vector2} + 3
    }
    {pred: predicate} subv4 {vecdest: destreg}, {vector1: srcreg}, {vector2: srcreg} => asm{
        {pred} sub {vecdest} + 0, {vector1} + 0, {vector2} + 0
        {pred} sub {vecdest} + 1, {vector1} + 1, {vector2} + 1
        {pred} sub {vecdest} + 2, {vector1} + 2, {vector2} + 2
        {pred} sub {vecdest} + 3, {vector1} + 3, {vector2} + 3
    }
    {pred: predicate} addv3 {vecdest: destreg}, {vector1: srcreg}, {vector2: srcreg} => asm{
        {pred} add {vecdest} + 0, {vector1} + 0, {vector2} + 0
        {pred} add {vecdest} + 1, {vector1} + 1, {vector2} + 1
        {pred} add {vecdest} + 2, {vector1} + 2, {vector2} + 2
    }
    {pred: predicate} subv3 {vecdest: destreg}, {vector1: srcreg}, {vector2: srcreg} => asm{
        {pred} sub {vecdest} + 0, {vector1} + 0, {vector2} + 0
        {pred} sub {vecdest} + 1, {vector1} + 1, {vector2} + 1
        {pred} sub {vecdest} + 2, {vector1} + 2, {vector2} + 2
    }
    {pred: predicate} scalev3 {vecdest: destreg}, {vector: srcreg}, {scalar: srcreg} => asm{
        {pred} mul {vecdest} + 0, {vector} + 0, {scalar}
        {pred} mul {vecdest} + 1, {vector} + 1, {scalar}
        {pred} mul {vecdest} + 2, {vector} + 2, {scalar}
    }

    ; Miscellaneous
    {pred: predicate} li {rd: destreg}, {imm: immediate32} => asm {
        {pred} lui {rd}, imm[31:16]
        {pred} lli {rd}, imm[15:0]
    }
    {pred: predicate} mov {rd: destreg}, {rs: srcreg} => asm {
        {pred} addi {rd}, {rs}, 0
    }
    {pred: predicate} trunc {rd: destreg}, {rs: srcreg} => asm {
        {pred} srl {rd}, {rs}, 10
        {pred} sll {rd}, {rd}, 10
    }
    {pred: predicate} nop => asm {
        {pred} addi $r0, $r0, 0
    }
}