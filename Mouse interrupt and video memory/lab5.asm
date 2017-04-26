.386

Data segment use16
	attrib db 10h; если значение = 10h - цвет ещё не выбрали
Data ends

Code segment use16
	assume cs:Code, ds:Data

HookMouse proc far
	push ds    
	push es
	pusha
	
	push 0b800h
	pop es
	push Data
	pop ds

	shr cx, 3
	shr dx, 3
	
	jne _not
	and bl, 01h; если нажали левую кнопку мыши
	je _skip
	cmp cx, 16h
	jae _skip
	
	; курсор мыши меняет цвет фона, поэтому прячем его
	
	mov ax, 02h
    int 33h
	
	; считываем символ и атрибут в текущей позиции курсора
	imul edx, 80*2
	lea ecx, [edx+ecx*2]
	mov ax, es:[ecx]
	shr ah, 4; сдвигаем старшую тетраду на место младшей
	mov attrib, ah
	
	; возвращаем курсор мыши
	mov ax, 01h
    int 33h
	
	jmp _skip
	_not:
	
	and bl, 02h; если нажали правую кнопку мыши
	je _skip
	cmp attrib, 10h; если забыли выбрать цвет в палитре
	je _skip
	
	; перед выводом нового символа прячем курсор мыши
	mov ax, 02h
    int 33h
	
	; высичтываем смещение и собственно выводим новый символ
	imul edx, 80*2
	lea ecx, [edx+ecx*2]
	mov ax, es:[ecx]
	mov ah, attrib
	mov es:[ecx], ax
	
	; возвращаем курсор мыши
	mov ax, 01h
    int 33h
	_skip:
	
	popa
	pop es
	pop ds
	retf
HookMouse endp

Begin:
	; устанавливаем текстовый режим 80х25(16 цветов,4 видеостраницы)
	mov ax, 03h
	int 10h
	
	push 0b800h
	pop es
	
	; выбераем яркость вместо мерцания
	mov ah, 10h
	mov al, 3
	mov bl, 0
	int 10h
	
	; выводим палитру 16-и цветов
	xor ax, ax
	xor bx, bx
	mov cx, 16
	_colors:
	mov es:[bx], ax
	add bx, 2
	add ah, 10h
	loop _colors
	
	; заполняем остальные строки символами
	mov di, 80*2; начиная с 1-ой строки
	mov	ax,	0707h
	mov cx, 80*24
	rep stosw
	
	; инициализируем мышь
	xor	ax,	ax
	int 33h
	
	; отображаем курсор
	mov ax, 01h
    int 33h
	
	; задаем пользовательский обработчик сообщений мыши
	mov ax, 0ch
	mov cx, 00001010b; отпускание правой и левой кнопки
	push cs
	pop es
	lea dx, HookMouse; es:dx - адрес обработчика
	int 33h
	
	; ожидаем нажатия любой клавиши клавиатуры
	mov ah, 00h
	int 16h
	
	; отменяем обработчик сообщений мыши
	xor cx, cx
	mov ax, 0ch
	int 33h

	mov ax, 4c00h
	int 21h
Code ends
end Begin