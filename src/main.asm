; BRAINFUCK INTERPRETER IN NASM x86 ASSEMBLY
; -------------------------------------
; by: @waytoounoriginal
; -------------------------------------

bits 32 ;define working on 32 bits



; export the run_isntructions in case it's used in c
global _run_instructions

%define CONSOLE_SUBSYS

%ifdef CONSOLE_SUBSYS
global start
%endif

%ifdef CONSOLE_SUBSYS
    extern exit, fopen, printf, scanf, fclose
    import exit msvcrt.dll
    import fopen msvcrt.dll
    import printf msvcrt.dll
    import scanf msvcrt.dll
    import fclose msvcrt.dll
%else
    extern _exit, _fopen, _printf, _scanf, _fclose
    
    %define exit _exit
    %define fopen _fopen
    %define printf _printf
    %define scanf _scanf
    %define fclose _fclose

%endif

extern  create_instruction
extern  _parse_file

%include "../../src/instruction_constants.asm"


segment data use32 class=data
    MEMORY_LIMIT equ 4096

    MEMORY resb MEMORY_LIMIT ; the memory block

    ; the memory block where instructions will be contained
    INSTRUCTION_ARRAY resd MEMORY_LIMIT


    ; lookup table for the labels
    __INSTRUCTION_LOOKUP_TABLE resd 9
    read_format db "%d", 0

    print_format db "%c", 0


    ; the test file
    test_file db "test.bf", 0
    mode db "r", 0
    file dd -1


segment code use32 class=code

    _run_instructions:
        ; int cdecl run_instructions(instr_t[] instructions, int number)
        ; -------------------------------
        ; INPUT:
        ;   number - the number of instructions to follow
        ;   instructions - the array of instructions
        ;
        ; OUTPUT:
        ;   - an integer, representing the status of the execution.
        ;       * -1 - the execution failed
        ;       * 0 - the execution succeeded
        
        push ebp
        mov ebp, esp

        mov ecx, [ebp + 12] ; number

        ; Reserve space for the program counter and for the address counter
        sub esp, 4

        mov word [ebp - 2], 0 ; PC
        mov word [ebp - 4], 0 ; Address pointer

        ; Reserve space for the temporary number
        sub esp ,4
        mov dword [ebp - 8], 0

        %define MACRO__PC word [ebp - 2]
        %define MACRO__Addr_pointer word [ebp - 4]
        %define MACRO__TMP dword [ebp - 8]


        .set_up_lookup_table:
            mov dword [__INSTRUCTION_LOOKUP_TABLE + 4 * INSTRUCTION_TYPE__MOVE_RIGHT], .move_right
            mov dword [__INSTRUCTION_LOOKUP_TABLE + 4 * INSTRUCTION_TYPE__MOVE_LEFT], .move_left
            mov dword [__INSTRUCTION_LOOKUP_TABLE + 4 * INSTRUCTION_TYPE__INCREMENT], .increment
            mov dword [__INSTRUCTION_LOOKUP_TABLE + 4 * INSTRUCTION_TYPE__DECREMENT], .decrement
            mov dword [__INSTRUCTION_LOOKUP_TABLE + 4 * INSTRUCTION_TYPE__OUTPUT], .output
            mov dword [__INSTRUCTION_LOOKUP_TABLE + 4 * INSTRUCTION_TYPE__INPUT], .input
            mov dword [__INSTRUCTION_LOOKUP_TABLE + 4 * INSTRUCTION_TYPE__LOOP_L], .loop_left
            mov dword [__INSTRUCTION_LOOKUP_TABLE + 4 * INSTRUCTION_TYPE__LOOP_R], .loop_right


        .run_instruction_loop:

            ; compare the current PC with the expected one
            cmp MACRO__PC, cx
            jae .exit


            ; load the current instruction in memory
            mov ebx, 0
            mov bx, MACRO__PC

            mov edx, dword [ebp + 8] ; instructions
            mov eax, [edx + ebx * 4] ; type | jump_to_value

            mov edx, 0
            ror eax, 4 * 4
            mov dx, ax

            jmp [__INSTRUCTION_LOOKUP_TABLE + edx * 4]


            .move_right:
                ; todo: check if the pointer can move right

                inc MACRO__Addr_pointer ; address counter
                jmp .increment_pc

            .move_left:
                ; todo: check if the pointer can move left

                dec MACRO__Addr_pointer
                jmp .increment_pc

            .increment:
                mov ebx, 0
                mov bx, MACRO__Addr_pointer
                inc byte [MEMORY + ebx]
                jmp .increment_pc

            .decrement:
                mov ebx, 0
                mov bx, MACRO__Addr_pointer
                dec byte [MEMORY + ebx]
                jmp .increment_pc

            .input:
                pusha

                ; scanf(%d, &tmp_number)
                push MACRO__TMP
                push dword read_format
                call [scanf]
                add esp, 4 * 2

                popa

                ; store the read number into the current memory
                mov eax, MACRO__TMP

                mov ebx, 0
                mov bx, MACRO__Addr_pointer

                mov byte [MEMORY + ebx], al

                jmp .increment_pc
                 

            .output:
                ; printf(format, ...)
                mov ebx, 0
                mov bx, MACRO__Addr_pointer

                mov eax, 0
                mov al, byte [MEMORY + ebx]

                pusha

                push eax
                push dword print_format
                call [printf]
                add esp, 4 * 2

                popa

                jmp .increment_pc

            .loop_left:
                ; test if the current cell is non-zero
                mov ebx, 0
                mov bx, MACRO__Addr_pointer

                cmp byte [MEMORY + ebx], 0
                jnz .increment_pc

                ; jump past the matching
                shr eax, 4 * 4
                mov MACRO__PC, ax
                jmp .run_instruction_loop

                jmp .increment_pc
                

            .loop_right:
                ; test if the pointer is 0
                mov ebx, 0
                mov bx, MACRO__Addr_pointer

                cmp byte [MEMORY + ebx], 0
                jz .increment_pc


                ; get the address to jump back to
                shr eax, 4 * 4
                mov MACRO__PC, ax
                jmp .run_instruction_loop

            .increment_pc:
                inc MACRO__PC
                jmp .run_instruction_loop


        .exit:
            mov esp, ebp
            pop ebp

            mov eax, 0

            ret

        .exit_failure:
            mov esp, ebp
            pop ebp

            mov eax, -1

            ret


        %undef MACRO__PC
        %undef MACRO__Addr_pointer
        %undef MACRO__TMP


    start:
        ; open the test file and test the parser
        ; eax = fopen(file, mode)
        push dword mode
        push dword test_file
        call [fopen]

        add esp, 4 * 2

        mov dword [file], eax

        ; eax = parse_file(INSTRUCTION_ARRAY, file)
        push dword [file]
        push dword INSTRUCTION_ARRAY
        call _parse_file
        add esp, 4 * 2

        ; run_isntructions(INSTRUCTION_ARRAY, eax)
        push eax
        push dword INSTRUCTION_ARRAY
        call _run_instructions
        add esp, 4

        ; fclose(file)
        push dword [file]
        call [fclose]
        add esp, 4


        exit_successfully:
            push dword 0
            call [exit]


