default rel

global RGB2YUV, YUV2RGB

section .text

RGB2YUV:
    push rbx
    push rbp
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r10, [rsp + 8 * 8 + 32 + 8] ; in_stride
    mov r11, [rsp + 8 * 8 + 32 + 16] ; out_stride

    sub rsp, 64
    vmovups [rsp],          xmm6
    vmovups [rsp + 16],     xmm7
    vmovups [rsp + 16 * 2], xmm8
    vmovups [rsp + 16 * 3], xmm9

    vmovaps xmm4, [shift_mask_ry]
    vmovaps xmm5, [add_zeroes_mask]
    vmovaps ymm6, [YrUgVb_coeffs]
    vmovaps ymm7, [YgUbVr_coeffs]
    vmovaps ymm8, [YbUrVg_coeffs]
    vmovaps ymm9, [free_term_ry]

    mov rsi, rcx ; in
    mov rdi, rdx ; out
    imul r8, 3 ; bytes_in_line

.loop_sse_ry:
    mov rcx, rsi ; _in
    mov rdx, rdi ; _out
    mov rax, r8 ; i

.loop_line_ry:
    vmovups xmm0, [rcx] ; rgb5
    add rcx, 12

    vmovups xmm1, xmm0
    vpshufb xmm1, xmm4 ; gbr
    vmovups xmm2, xmm1
    vpshufb xmm2, xmm4 ; brg

    vpmovzxbw ymm0, xmm0
    vpmovzxbw ymm1, xmm1
    vpmovzxbw ymm2, xmm2

    vpmullw ymm0, ymm6 ; YrUgVb
    vpmullw ymm1, ymm7 ; YgUbVr
    vpmullw ymm2, ymm8 ; YbUrVg

    vpaddw ymm0, ymm9
    vpaddw ymm0, ymm1
    vpaddw ymm0, ymm2 ; YUV

    vpsrlw ymm0, 8

    vextracti128 xmm1, ymm0, 0 ; lo
    vextracti128 xmm2, ymm0, 1 ; hi

    vpackuswb xmm1, xmm2
    vpshufb xmm1, xmm5

    vmovups [rdx], xmm1
    add rdx, 16

    sub rax, 12
    cmp rax, 16
    jae .loop_line_ry

    cmp rax, 0
    jna .loop_line_end_ry
.loop_tail_ry:
    movzx r12, BYTE [rcx] ; r
    inc rcx
    movzx r13, BYTE [rcx] ; g
    inc rcx
    movzx r14, BYTE [rcx] ; b
    inc rcx

    mov rbx, r12 ; Y
    imul rbx, 76
    mov r15, r13
    imul r15, 150
    add rbx, r15
    mov r15, r14
    imul r15, 29
    add rbx, r15

    mov r15, r12 ; U
    imul r15, -43
    mov rbp, r13
    imul rbp, -84
    add r15, rbp
    mov rbp, r14
    imul rbp, 128
    add r15, rbp

    imul r12, 128 ; V
    imul r13, -107
    imul r14, -20
    add r12, r13
    add r12, r14

    add rbx, 0
    add r15, 32767
    add r12, 32767

    shr rbx, 8
    shr r15, 8
    shr r12, 8

    shl r12d, 16
    add r12b, r15b
    shl r12w, 8
    add r12b, bl

    mov [rdx], r12d
    add rdx, 4

    sub rax, 3
    jnz .loop_tail_ry
.loop_line_end_ry:
    add rsi, r10
    add rdi, r11

    dec r9
    jnz .loop_sse_ry

;--------------------------------------

    vmovups xmm6, [rsp]
    vmovups xmm7, [rsp + 16]
    vmovups xmm8, [rsp + 16 * 2]
    vmovups xmm9, [rsp + 16 * 3]
    add rsp, 64

    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    ret

YUV2RGB:
    push rbx
    push rbp
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r10, [rsp + 8 * 8 + 32 + 8] ; in_stride
    mov r11, [rsp + 8 * 8 + 32 + 16] ; out_stride

    sub rsp, 64
    vmovups [rsp],          xmm6
    vmovups [rsp + 16],     xmm7
    vmovups [rsp + 16 * 2], xmm8
    vmovups [rsp + 16 * 3], xmm9

    vmovaps xmm4, [shift_mask_yr]
    vmovaps xmm5, [remove_zeroes_mask]
    vmovaps ymm6, [RyGuBv_coeffs]
    vmovaps ymm7, [RuGvBy_coeffs]
    vmovaps ymm8, [RvGyBu_coeffs]
    vmovaps ymm9, [free_term_yr]

    mov rsi, rcx ; in
    mov rdi, rdx ; out
    imul r8, 4 ; bytes_in_line

.loop_sse_yr:
    mov rcx, rsi ; _in
    mov rdx, rdi ; _out
    mov rax, r8 ; i

.loop_line_yr:
    vmovups xmm0, [rcx] ; yuv4
    add rcx, 16

    vmovups xmm1, xmm0
    vpshufb xmm1, xmm4 ; uvy
    vmovups xmm2, xmm1
    vpshufb xmm2, xmm4 ; vyu

    vpmovzxbw ymm0, xmm0
    vpmovzxbw ymm1, xmm1
    vpmovzxbw ymm2, xmm2

    vpmullw ymm0, ymm6 ; RyGuBv
    vpmullw ymm1, ymm7 ; RuGvBy
    vpmullw ymm2, ymm8 ; RvGyBu

    vpaddw ymm0, ymm1
    vpaddw ymm0, ymm2
    vpsubw ymm0, ymm9 ; RGB

    vpsraw ymm0, 7

    vextracti128 xmm1, ymm0, 0 ; lo
    vextracti128 xmm2, ymm0, 1 ; hi

    vpackuswb xmm1, xmm2
    vpshufb xmm1, xmm5

    vmovups [rdx], xmm1
    add rdx, 12

    sub rax, 16
    cmp rax, 16
    jae .loop_line_yr

    cmp rax, 0
    jna .loop_line_end_yr
.loop_tail_yr:
    xor rbx, rbx
    xor r12, r12
    xor r13, r13
    xor r14, r14

    mov ebx, DWORD [rcx]
    add rcx, 4

    mov r12b, bl
    shr ebx, 8
    mov r13b, bl
    shr ebx, 8
    mov r14b, bl

    mov rbx, r12 ; R
    imul rbx, 128
    mov r15, r14
    imul r15, 179
    add rbx, r15
    sub rbx, 22912

    mov r15, r12 ; G
    imul r15, 128
    mov rbp, r13
    imul rbp, -44
    add r15, rbp
    mov rbp, r14
    imul rbp, -91
    add r15, rbp
    add r15, 17280

    imul r12, 128 ; B
    imul r13, 226
    add r12, r13
    sub r12, 28928

    shr rbx, 7
    shr r15, 7
    shr r12, 7

    mov [rdx], bl
    inc rdx
    mov [rdx], r15b
    inc rdx
    mov [rdx], r12b
    inc rdx

    sub rax, 4
    jnz .loop_tail_yr
.loop_line_end_yr:
    add rsi, r10
    add rdi, r11

    dec r9
    jnz .loop_sse_yr

;--------------------------------------

    vmovups xmm6, [rsp]
    vmovups xmm7, [rsp + 16]
    vmovups xmm8, [rsp + 16 * 2]
    vmovups xmm9, [rsp + 16 * 3]
    add rsp, 64

    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    ret

section .rodata
align 16
shift_mask_ry:
    db 1, 2, 0, 4, 5, 3, 7, 8, 6, 10, 11, 9, 13, 14, 12, 15

align 16
shift_mask_yr:
    db 1, 2, 0, 3, 5, 6, 4, 7, 9, 10, 8, 11, 13, 14, 12, 15

align 16
add_zeroes_mask:
    db 0, 1, 2, -1, 3, 4, 5, -1, 6, 7, 8, -1, 9, 10, 11, -1

align 16
remove_zeroes_mask:
    db 0, 1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 14, -1, -1, -1, -1

align 32
YrUgVb_coeffs:
    dw 76, -84, -20, 76, -84, -20, 76, -84, -20, 76, -84, -20, 76, -84, -20, 0

align 32
YgUbVr_coeffs:
    dw 150, 128, 128, 150, 128, 128, 150, 128, 128, 150, 128, 128, 150, 128, 128, 0

align 32
YbUrVg_coeffs:
    dw 29, -43, -107, 29, -43, -107, 29, -43, -107, 29, -43, -107, 29, -43, -107, 0

align 32
RyGuBv_coeffs:
    dw 128, -44, 0, 0, 128, -44, 0, 0, 128, -44, 0, 0, 128, -44, 0, 0, 128, -44, 0, 0

align 32
RuGvBy_coeffs:
    dw 0, -91, 128, 0, 0, -91, 128, 0, 0, -91, 128, 0, 0, -91, 128, 0, 0, -91, 128, 0

align 32
RvGyBu_coeffs:
    dw 179, 128, 226, 0, 179, 128, 226, 0, 179, 128, 226, 0, 179, 128, 226, 0, 179, 128, 226, 0

align 32
free_term_ry:
    dw 0, 32767, 32767, 0, 32767, 32767, 0, 32767, 32767, 0, 32767, 32767, 0, 32767, 32767, 0

align 32
free_term_yr:
    dw 22912, -17280, 28928, 0, 22912, -17280, 28928, 0, 22912, -17280, 28928, 0, 22912, -17280, 28928, 0
