; PARSER.ASM
; -------------------------------
bits 32

%include "../../src/instruction_constants.asm"

global _parse_file

%define CONSOLE_SUBSYS


%ifdef CONSOLE_SUBSYS
    extern fgets
    import fgets msvcrt.dll
%else
    extern _fgets

    %define fgets _fgets
%endif

extern create_instruction


segment parser_data use32 class=data
    ; the program counter used for parsing
    __PC dw 0


    __LOOP_POINTER_STACK resw 100

    __MAX_LENGTH equ 255
    __BUFFER resb __MAX_LENGTH

    __LOOKUP_TABLE resd 255


segment parser_code use32 class=code

    _parse_file:
        ; int cdecl parse_file(instruction_t arr[], FILE* file)
        ; -----------------------------------------------
        ; INPUT:
        ;   arr - the output array of the instructions
        ;   file - the file to read from

        ; OUTPUT:
        ;   - the number of instructions that have been parsed

            push ebp
            mov ebp, esp

            ; set the progam counter
            mov word [__PC], 0

            ; reserve space for 2 variables on the stack
            sub esp, 8

            ; reserve space for the current loop_stack address
            mov dword [ebp - 4], __LOOP_POINTER_STACK

            ; reserve space for the arr param
            mov edi, dword [ebp + 8] ; arr

            mov dword [ebp - 8], edi

            mov eax, dword [ebp + 12] ; file
        
        .set_up_lookup_table:
            mov ecx, 255

            .set_loop:
                mov dword [__LOOKUP_TABLE + ecx * 4], .other_tok
                loop .set_loop

            mov dword [__LOOKUP_TABLE + INSTRUCTION_CHAR__MOVE_RIGHT * 4], .mv_r_tok
            mov dword [__LOOKUP_TABLE + INSTRUCTION_CHAR__MOVE_LEFT * 4], .mv_l_tok
            mov dword [__LOOKUP_TABLE + INSTRUCTION_CHAR__INCREMENT * 4], .inc_tok
            mov dword [__LOOKUP_TABLE + INSTRUCTION_CHAR__DECREMENT * 4], .dec_tok
            mov dword [__LOOKUP_TABLE + INSTRUCTION_CHAR__OUTPUT * 4], .out_tok
            mov dword [__LOOKUP_TABLE + INSTRUCTION_CHAR__INPUT * 4], .in_tok
            mov dword [__LOOKUP_TABLE + INSTRUCTION_CHAR__LOOP_L * 4], .loop_l_tok
            mov dword [__LOOKUP_TABLE + INSTRUCTION_CHAR__LOOP_R * 4], .loop_r_tok


        .read_line_loop:
            ; fgets(buffer, size, file)
            push dword [ebp + 12] ; file
            push dword __MAX_LENGTH
            push dword __BUFFER
            call [fgets]
            add esp, 4 * 3

            cmp eax, 0
            jz .exit

            ; Go through the line and find instructions
            mov esi, __BUFFER
            .parse_line_loop:
                mov eax, 0 ; promoting the  character
                lodsb
                cmp al, 0
                je .end_line

                jmp [__LOOKUP_TABLE + eax * 4]

                .mv_r_tok:
                    mov dx, INSTRUCTION_TYPE__MOVE_RIGHT
                    jmp .create_instruction

                .mv_l_tok:
                    mov dx, INSTRUCTION_TYPE__MOVE_LEFT
                    jmp .create_instruction

                .inc_tok:
                    mov dx, INSTRUCTION_TYPE__INCREMENT
                    jmp .create_instruction

                .dec_tok:
                    mov dx, INSTRUCTION_TYPE__DECREMENT
                    jmp .create_instruction

                .out_tok:
                    mov dx, INSTRUCTION_TYPE__OUTPUT
                    jmp .create_instruction

                .in_tok:
                    mov dx, INSTRUCTION_TYPE__INPUT
                    jmp .create_instruction

                .loop_l_tok:
                    mov dx, INSTRUCTION_TYPE__LOOP_L
                    ; add the current counter on the stack
                    mov ebx, dword [ebp - 4]
                    mov ax, word [__PC]
                    mov word [ebx], ax

                    ; increment the stack
                    add dword [ebp - 4], 2

                    jmp .create_instruction

                .loop_r_tok:
                    mov dx, INSTRUCTION_TYPE__LOOP_R
                    mov eax, 0

                    ; pop the stack
                    ; decrement the stack
                    sub dword [ebp - 4], 2
                    mov ebx, dword [ebp - 4]
                    mov ax, word [ebx]

                    ; set the jump_to address of the matching brackets
                    mov ebx, dword [ebp + 8]
                    mov ecx, dword [ebx + eax * 4]

                    mov cx, word [__PC]
                    inc cx

                    mov dword [ebx + eax * 4], ecx


                    jmp .create_instruction

                .other_tok:
                    ; get back
                    jmp .parse_line_loop

                .create_instruction:
                    ; edx:eax = create_instruction(ax, dx)
                    push word dx
                    push word ax
                    call create_instruction
                    add esp, 4

                    ; store it in the instruction_array
                    mov edi, dword [ebp - 8]
                    mov dword [edi], eax
                    add edi, 4
                    mov dword [ebp - 8], edi

                    ; increment the pc
                    inc word [__PC]

                jmp .parse_line_loop

            .end_line:
                jmp .read_line_loop

        .exit:
            mov esp, ebp
            pop ebp

            mov eax, 0
            mov ax, word [__PC]

            ret