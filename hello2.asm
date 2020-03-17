global _start

section .bss
    bufor: resb 8   ; tworzymy bufor na tekst

section .rodata
    NEWLINE: db `\n`

section .text

_start:
    mov rcx, [rsp]  ; kopiuje wartość wierzchołka stosu do rejestru rcx. rsp to adres wierzchołka stosu
                    ; na stosie są ośmiobajtowe segmentu z adresami do argumentów
                    ; czyli trzeba się odwołać dwa razy, napierw do zerowego arumentu [rsp + 8]
                    ; a potem znowu kwadratowymi nawiasami do tego co tam jest
    add cl, '0'     ; cl to 8 bitów rcx'a, czyli pojedynczy znak. 
    mov [bufor], cl
    mov rsi, bufor   ; przenosimy do rsi liczbę argumentów
    mov rdi, 1  ; std out
    mov rdx, 1  ; buffer size
    mov rax, 1  ; sys_write
	syscall
    mov rsi, NEWLINE
    syscall
	mov rax, 60 ; sys_exit
	syscall
