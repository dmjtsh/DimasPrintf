global DimasPrintf

extern GetStdHandle
extern WriteFile

section .data
    buffer DB 512 DUP(0)

section .text

;------------------------------------------------------------
; Dimas Printf
; Entry: rcx: format str to output
; Destr: rcx, rdx
;------------------------------------------------------------
DimasPrintf:
    xor rdx, rdx

    .Cycle:
    cmp byte [rcx], 0   ; if str[i] == '\0'
    je .End

    cmp rdx, 512        ; if buffer full
    jne .CycleBody
    call PrintBuffer
    mov rdx, 0

    .CycleBody:

    mov byte r8b, [rcx]

   ; cmp r8b, '%'
    ;jne .WriteSymb
   ; call PrintSpecialSymb

    .WriteSymb:
    mov r9, buffer
    mov byte [r9+rdx], r8b

    inc rdx
    inc rcx
    jmp .Cycle

    .End:
    call PrintBuffer

    ret

;------------------------------------------------------------
; Print Buffer Func
; Entry: rdx - num of symbs to write
; Destr:
;------------------------------------------------------------
PrintBuffer:
    sub rsp, 40

    mov r8d, edx        ; STR_LEN (WriteFile)

    mov rdx, buffer     ; Message
    mov rcx, -11        ; GetStdHandle - STD_OUTPUT

    call GetStdHandle
    mov rcx, rax        ; Handle
    xor r9, r9          ; Number of Bytes Written
    mov qword [rsp+32], 0

    call WriteFile
    add rsp, 40

    ret

;------------------------------------------------------------
; Print Special Symb Func
; Entry: rcx - '%' symb address, rdx - buffer counter
; Destr:
;------------------------------------------------------------
PrintSpecialSymb:

    ret
