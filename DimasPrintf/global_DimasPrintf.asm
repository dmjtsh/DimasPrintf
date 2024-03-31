global DimasPrintf

extern GetStdHandle
extern WriteFile

HEX     equ 16
DECIMAL equ 10
BINARY  equ 2

%macro MULTI_PUSH 1-*
    %rep %0
        push %1
        %rotate 1
    %endrep
%endmacro

%macro MULTI_POP 1-*
    %rep %0
        pop %1
        %rotate 1
    %endrep
%endmacro

section .data
    buffer DB 512 DUP(0)

section .text

;------------------------------------------------------------
; Dimas Printf
; Entry: rcx: format str to output
; Regs to save: rcx, rdx, r8, r9, r11 - buffer counter, r13 - num of args written, rax - current stack arg (if it exists)
;------------------------------------------------------------
DimasPrintf:
    mov rax, rsp
    add rax, 40

    xor r11, r11            ; buffer counter
    xor r13, r13            ; num of args written

    .Cycle:
    cmp byte [rcx], 0       ; if str[i] == '\0'
    je .End

    cmp r11, 512            ; if buffer full
    jne .CycleBody

    MULTI_PUSH rcx, rdx, r8, r9
    call PrintBuffer
    MULTI_POP  r9, r8, rdx, rcx
    xor r11, r11            ; zeroing r11

    .CycleBody:

    mov byte r10b, [rcx]    ; symb

    cmp r10b, '%'
    jne .WriteSymb
    call PrintSpecialSymb
    jmp .CycleEnd

    .WriteSymb:
    mov r12, buffer
    mov byte [r12+r11], r10b

    .CycleEnd:
    inc r11
    inc rcx
    jmp .Cycle

    .End:
    call PrintBuffer

    ret

;------------------------------------------------------------
; Print Buffer Func
; Entry: r11 - num of symbs to write
; Destr: rcx, rdx, r8, r9
;------------------------------------------------------------
PrintBuffer:
    sub rsp, 40         ; The fuck??????????????????????

    mov rdx, buffer     ; Message
    mov rcx, -11        ; GetStdHandle - STD_OUTPUT

    call GetStdHandle
    mov r8d, r11d       ; STR_LEN (WriteFile)
    mov rcx, rax        ; Handle
    xor r9, r9          ; Number of Bytes Written
    mov qword [rsp+32], 0

    call WriteFile
    add rsp, 40

    ret

;------------------------------------------------------------
; Print Special Symb Func
; Entry: rcx - '%' symb address, rdx - buffer counter, r11 - num of args written
; Destr: r10, r12, r14, rdi, rsi, rbx
;------------------------------------------------------------
PrintSpecialSymb:
    inc rcx
    xor r10, r10

    mov r14b, [rcx]         ; tmp var

    mov r10b, r14b
    shl r10, 3
    mov rdi, JumpTable
    add r10, rdi

    mov r12, buffer         ; moving address of buffer to r12 for convenience
    jmp [r10]               ; symbol*8 + JumpTable address

    PercentCase:
    mov byte [r12+r11], r14b
    ret

    BinaryCase:
    call GetProperArg
    mov rbx, BINARY
    call FillBufferWithNum
    ret

    CharCase:
    call GetProperArg
    mov byte [r12+r11], r15b
    ret

    DecimalCase:
    call GetProperArg
    mov rbx, DECIMAL
    call FillBufferWithNum
    ret

    StringCase:
    call GetProperArg
    call FillBufferWithString
    ret

    HexCase:
    call GetProperArg
    mov rbx, HEX
    call FillBufferWithNum
    ret

    Exit:
    mov byte [r12+r11], '%'
    inc r11
    mov byte [r12+r11], r14b
    ret

JumpTable:
    times '%' -  0      dq Exit
    dq PercentCase
    times 'b' - '%' - 1 dq Exit
    dq BinaryCase
    dq CharCase
    dq DecimalCase
    times 's' - 'd' - 1 dq Exit
    dq StringCase
    times 'x' - 's' - 1 dq Exit
    dq HexCase
    times 255 - 's' - 1 dq Exit

;------------------------------------------------------------
; GetProperArg Func
; Entry: r13
; Used for:
; Ret: R15 - proper arg
; Destr: r10, rdi
;------------------------------------------------------------
GetProperArg:
    xor r10, r10

    mov r10, r13

    inc r13         ; Count of Args Written ++
    cmp r13, 4
    jae RetStackArg ; if Count Of Args >= 4

    shl r10, 3

    mov rdi, ArgTable
    add r10, rdi
    jmp [r10]

    RetRDX:
    mov r15, rdx
    ret

    RetR8:
    mov r15, r8
    ret

    RetR9:
    mov r15, r9
    ret

    RetStackArg:        ; TODO: исправить
    push rbp
    mov rbp, rax
    mov r15, [rbp]
    add rax, 8
    pop rbp
    ret

ArgTable:
    dq RetRDX
    dq RetR8
    dq RetR9

;------------------------------------------------------------
; Fill Buffer With Num Func
; Entry RBX - Notation of Num
; Destr: none
;------------------------------------------------------------
FillBufferWithNum:
    MULTI_PUSH rax, rcx, rdx, rsi, r10, r13, r14        ; TODO: проверка переполнения буфера + добавить минус

    cmp r15, 0
    ;ja .PositiveNum

    ;mov byte [r12+r11], '-'
    ;inc r11
    ;neg r15

    ;.PositiveNum:

    mov rcx, rbx
    mov rsi, r11
    mov rax, r15

    .Cycle:
    cmp rax, 0
    je .CycleEnd

    xor rdx, rdx
    idiv rcx                        ; decimal / notation

    mov byte [r12+r11], dl

    cmp dl, 10
    jae .PrintHex

    .PrintDecimalAndBinary:          ; decimal % notation
    add byte [r12+r11], '0'
    jmp .EndPrint

    .PrintHex:
    add byte [r12+r11], 55

    .EndPrint:
    inc r11

    jmp .Cycle

    .CycleEnd:

    mov rdx, r11                    ; SAVE r11
    dec r11
    .ReverseString:
    cmp r11, rsi
    jbe .FuncEnd

    ; SWAP
    mov byte r13b, [r12+r11]
    mov byte r14b, [r12+rsi]
    mov byte [r12+r11], r14b
    mov byte [r12+rsi], r13b

    dec r11
    inc rsi
    jmp .ReverseString

    .FuncEnd:
    mov r11, rdx                    ; SAVE r11
    dec r11

    MULTI_POP r14, r13, r10, rsi, rdx, rcx, rax
    ret

;------------------------------------------------------------
; Fill Buffer With String Func
; Entry: none
; Destr: none
;------------------------------------------------------------
FillBufferWithString:

    .Cycle:
    cmp byte [r15], 0
    je .CycleEnd

    mov byte r10b, [r15]
    mov byte [r12+r11], r10b

    inc r11
    inc r15
    jmp .Cycle
    .CycleEnd:

    dec r11

    ret
