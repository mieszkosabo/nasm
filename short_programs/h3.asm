section .text
    global _start


_start:
    mov r12, [rsp]          ; liczba argumentów
    mov rdx, 1              ; będziemy używać do incrementowania?
    cmp r12, 1
    je  exit
    add rsp, 8              ; omijamy liczbę argumentów
    xor r11, r11            ; zerujemy r11, będziemy tam zliczać znaki
nextArg:
    mov rsi, [rsp + 8 * rdx]  ; pierwszy od lewej argument
    inc rdx
    call count_letters_in_arg
    dec r12
    cmp r12, 1
    je print
    jmp nextArg

count_letters_in_arg:       ; w rsi mamy wskaźnik do napisu
    cmp [rsi], byte 0       ; sprawdzamy czy mamy koniec słowa
    je return_from_count
    inc r11                 ; zwiększamy liczbę liter
    inc rsi                 ; przesuwamy wskaźnik w słowie na następny bajt
    jmp count_letters_in_arg

return_from_count:
    inc r11                 ; liczymy też miejsce na bajt zerowy
    ret

print:
    mov rax, 1
    mov rdi, 1
    mov rsi, [rsp + 8]
    mov rdx, r11
    syscall
    jmp exit

exit:
    mov rax, 60
    syscall