; INSTRUCTIONS.ASM
; ------------------------------

; C variant:
; struct instruction_t {
;   int16_t _jump_location
;   byte/unsigned char _instruction_type
;}
; - 3 bytes - aligning to dword

bits 32

global  create_instruction


%include "../../src/instruction_constants.asm"


segment instructions_data use32 class=data

segment instructions_code use32 class=code


create_instruction:
    ; instruction_t cdecl create_instruction(int16_t jump_address, int32_t instruction_type)
    ; -----------------------------------------------
    ; INPUT:
    ;   instruction_type - an 8-bit integer representing the type of the instruction
    ;   jump_address - the address of the program counter to jump to; specific to loop instructions
    ;
    ; OUTPUT:
    ;   - an instruction_t struct, stored in eax
    ;       * the jump_to value is stored in ax
    ;       * the instruction type is stored in the higher part of eax
    push ebp
    mov ebp, esp

    mov eax, dword [ebp + 8]

    mov esp, ebp
    pop ebp

    ret

