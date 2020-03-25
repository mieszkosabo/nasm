

section .rodata

HELLO:		db "Hello World!", 10	; 10 = '/n' = 0xa (w 16stkowym)
HELLO_LEN: equ $ - HELLO	; $ to jest wskaźnik na ostatnie polecenie jakby
						; czyli na newline po hello world. Czyli odejmujemy
						; wskaźniki i dostajemy długość słowa. Taki triczek.


section .text
	global _start

_start:
	mov rdi, 1
	mov rsi, HELLO
	mov rdx, HELLO_LEN
	mov rax, 1
	syscall
	jmp .exit

.exit:
	mov rax, 60
	syscall
