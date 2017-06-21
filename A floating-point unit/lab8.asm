.386

scale macro p1
    fld max_&p1
    fsub min_&p1
    fild max_crt_&p1
    fdivp st(1), st(0)
    fstp scale_&p1
endm

color_axis equ 2bh
color_graph equ 3bh

Data segment use16
    min_x dq -15.0      ; мінімальне значення по осі х
    max_x dq 15.0       ; максимальне значення по осі х
    max_crt_x dw 320    ; максимальна кількість точок на екрані по осі х
    crt_x dw ?          ; екранна координата по осі х
    scale_x dq ?        ; масштаб по осі х

    min_y dq -15.0
    max_y dq 15.0
    max_crt_y dw 200
    crt_y dw ?
    scale_y dq ?

    color_dot db 0
    buff dw ?
    step dq 0.01
    const_two dd 2
Data ends

Code segment use16
    assume cs:Code, ds:Data
draw_axis proc
    fldz
    call get_y

    mov crt_x, 0
    mov cx, max_crt_x
    mov color_dot, color_axis

x_axis:
    call draw_point
    inc crt_x
    loop x_axis

    fld max_x
    fsub min_x
    frndint
    fistp buff
    mov cx, buff

    fld min_x
    frndint
    dec crt_y

x_scale:
    fld st(0)
    call get_x
    call draw_point

    fld1
    faddp st(1), st(0)
    loop x_scale
    ffree st(0)

    fldz
    call get_x
    mov crt_y, 0
    mov cx, max_crt_y

y_axis:
    call draw_point
    inc crt_y
    loop y_axis

    fld max_y
    fsub min_y
    frndint
    fistp buff
    mov cx, buff

    fld min_y
    frndint
    dec crt_x

y_scale:
    fst st(1)
    call get_y
    call draw_point
    
    fld1
    faddp st(1), st(0)
    fcom max_y
    loop y_scale
    ffree st(0)

    ret
draw_axis endp

get_x proc
    fsub min_x
    fdiv scale_x
    frndint
    fistp crt_x
    ret
get_x endp

get_y proc
    fcom min_y
    fstsw ax
    sahf
    jc y_minus

    fcom max_y
    fstsw ax
    sahf
    ja y_plus

    fsub min_y
    fdiv scale_y
    frndint
    fistp crt_y

    mov ax, max_crt_y
    sub ax, crt_y
    mov crt_y, ax

    jmp y_else
y_minus:
    fdecstp
    mov ax, max_crt_y
    mov crt_y, ax
    jmp y_else
y_plus:
    fdecstp
    mov crt_y, 0
y_else:
    ret
get_y endp

draw_point proc
    mov ax, 0a000h
    mov es, ax

    mov si, crt_x
    mov di, crt_y
    mov ax, max_crt_x
    mul di
    add ax, si

    mov bx, ax
    mov al, color_dot
    mov byte ptr es:[bx], al

    ret
draw_point endp

func proc
    fld st(0)
    fld st(0)
    fild const_two
    fdivp st(1), st(0)
    fsin
    fxch st(1)
    fsin
    faddp st(1), st(0)

    ret
func endp

draw_graph proc
    mov color_dot, color_graph

    fld min_x
graph_loop:
    fld st(0)
    fld st(0)

    call get_x
    call func
    call get_y
    call draw_point

    fld step
    faddp st(1), st(0)
    fcom max_x
    fstsw ax

    sahf
    jna graph_loop

    ffree st(0)
    ret
draw_graph endp

Begin:
    push Data
    pop ds

    mov ax, 13h
    int 10h

    finit
    scale x
    scale y

    call draw_axis
    call draw_graph

    mov ah, 8
    int 21h

    mov ax, 3
    int 10h

    mov ax, 4c00h
    int 21h
Code ends
end Begin