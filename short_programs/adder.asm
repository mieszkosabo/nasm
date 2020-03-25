section .rodata
    SYS_WRITE:   equ 1
    SYS_EXIT:    equ 60
    STD_IN:      equ 1

    NEW_LINE:       db  0xa
    NEW_LINE_LEN:   equ $ - NEW_LINE
    WRONG_ARGC:     db "Must be two arguments", 10
    WRONG_ARGC_LEN: equ $ - WRONG_ARGC

section .text
    global _start

_start:
    mov rcx, [rsp]  ; kopiujemy ilość argumentów do rcx
    cmp rcx, 3
    jne argcError   ; jeśli nie mamy 2 argumentów z linii to kończymy

    mov rsi, [rsp + 8 * 2] ; pierwszy argument
    call str_to_int     ; umieszcza liczbę (pierwszy arg) do rejestru rax
    mov r10, rax        ; przenosimy do r10

    mov rsi, [rsp + 8 * 3] ; drugi arg
    call str_to_int
    mov r11, rax        ; drugi argument umieszczamy w r11

    add r10, r11        ; wynik będzie się znajdował w r10

    mov rax, r10        ; przenosimy wynik dodawania do rax
    xor r12, r12        ; będziemy używać r12 jako licznika potem
    
    jmp int_to_str

exit:
    mov rax, SYS_EXIT
    syscall    

argcError:
    mov rax, SYS_WRITE
    mov rdi, STD_IN
    mov rsi, WRONG_ARGC
    mov rdx, WRONG_ARGC_LEN
    syscall
    jmp exit

str_to_int:
    xor rax, rax        ; zerujemy rax'a
    mov rcx, 10         ; będziemy w każdym obrocie pętli mnożyć przez 10
next:
    cmp [rsi], byte 0   ; porównujemy bajt rsi z '\0', żeby spw czy już nie koniec napisu
    je return_str       ; koniec pętli
    mov bl, [rsi]       ; bl to bajtowa wersja rejestru rbx
    sub bl, 48          ; z kodu ascii np. '5' robimy 5
    mul rcx             ; mnożymy rax przez rcx, czyli 10
    add rax, rbx        ; dodajemy do aktualnego wyniku kolejną cyfrę
    inc rsi             ; przesuwamy wskaźnik na nast bajt
    jmp next

return_str:
    ret

int_to_str:
    mov rdx, 0
    mov rbx, 10
    div rbx             ; dzieli rax przez dbx. Reszta z dzielenia trafia do rdx
    add rdx, 48         ; zamieniamy cyfrę na kod ascii
    add rdx, 0x0        ; tak się musi kończyć string
    push rdx            ; wrzucamy ziomala na stos
    inc r12             ; chcemy zliczać cyfry, by wiedzieć jak długi napis wyprintować potem
    cmp rax, 0          ; czy koniec?
    jne int_to_str
    jmp print

print:
    mov rax, 1
    mul r12             ; sprawdzić czuy może nie wystarczy przenieść?
    mov r12, 8
    mul r12
    mov rdx, rax        ; długośc gościa

    mov rax, SYS_WRITE
    mov rdi, STD_IN
    mov rsi, rsp        ; wierzchołek stosu to to co printujemy
    syscall
    
    mov rsi, NEW_LINE
    mov rdx, NEW_LINE_LEN
    syscall

    jmp exit

