global DimasPrintf

extern GetStdHandle
extern WriteFile

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
; Regs to save: rcx, rdx, r8, r9, r11 - buffer counter, r13 - num of args written
;------------------------------------------------------------
DimasPrintf:
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

    ;cmp r10b, '%'
    ;jne .WriteSymb
    ;call PrintSpecialSymb
    ;jmp .CycleEnd

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
    sub rsp, 40

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
; Used for:
;------------------------------------------------------------
;PrintSpecialSymb:
   ;inc rcx

   ;mov r10b, [rcx]
   ;shl r10, 3
   ;add r10, JumpTable
   ;;jmp [r10]

   ;PercentCase:
   ;mov r12, buffer
   ;mov byte [r12+rdx], r10b
   ;ret

   ;ByteCase:

   ;CharCase:

   ;StringCase:

   ;Exit:
   ;; just print this symb
   ;ret

;JumpTable:
;    times '%' -  0      dq Exit
;    dq PercentCase
;    times 'b' - '%' - 1 dq Exit
;    dq ByteCase
;    dq CharCase
;    times 's' - 'c' - 1 dq Exit
;    dq StringCase
;    times 255 - 's' - 1 dq Exit
