SYS_WRITE   equ 1
SYS_EXIT    equ 60
SYS_READ    equ 0
STD_IN      equ 0
STD_OUT     equ 1
ALPHABET_SIZE   equ 42
BUFFER_SIZE equ 4096

global _start

section .data
    Linv   TIMES 42 db  0
    Rinv   TIMES 42 db  0
    Tinv   TIMES 42 db  0

section .bss
    buffer  resb    BUFFER_SIZE
    l       resb    1
    r       resb    1

section .text

%macro checkRange 0         
    cmp     cl, dl       ; w cl znajduje się '1', a w al 'Z'
    ja      error           ; '1' > znak
    cmp     dl, al
    ja      error           ; znak > 'Z'
%endmacro

; sprawdza, czy w rsi jest poprawny parametr L, R lub T.
; parametrem jest przesunięcie względem rsp - wskaźnik do parametru
; w r8 jest wskaźnik do permutacji odwrotnej, początowo wypełnionej
; zerami.
%macro  checkParam 1
    mov rsi, [rsp + %1]         ; przenosimy odpowiedni napis do rsi
    mov cl, '1'                 ; akceptowane są znaki z przedziału
    mov al, 'Z'                 ; 1 - Z
    xor r9, r9                  ; r9 będzie licznikiem
    %%loop:
        movzx   edx, byte [rsi] ; w rax mamy znak z permutacji
        test    rdx, rdx        ; sprawdź, czy koniec napisu
        jz %%return_from_check
        checkRange              ; sprawdź, czy znak jestw akceptowalnym zakresie
        cmp byte [r8 + rdx - '1'], 0 ; sprawdź, czy nie pojawił się ten znak już
        jne     error           ; jeśli się pojawił, to nie jest permutacja
        mov [r8 + rdx - '1'], r9b   ; Inv['z'] = licznik++;
        inc     r9                  ; TODO inv może też być + '1'?
        inc     rsi
        jmp     %%loop
    %%return_from_check:
        cmp     r9, 42          ; parametry L, R i T muszą mieć 42 znaki
        jne     error
%endmacro

%macro  checkKey 0
    mov rsi, [rsp + 8 * 5]      ; umieszczamy w rsi wskaźnik do klucza
    mov cl, '1'                 ; akceptowane są znaki z przedziału
    mov al, 'Z'                 ; 1 - Z

    cmp     [rsi], byte 0       ; sprawdź, czy koniec napisu
    je      error
    checkRange                  ; sprawdź, czy znak jestw akceptowalnym zakresie
    mov     [l], rsi
    sub byte [l], 49            ; normalizujemy l do liczby
    inc     rsi
    
    cmp     [rsi], byte 0       ; teraz patrzymy na r
    je      error
    checkRange
    mov     [r], rsi
    sub byte [r], 49            ; normalizujemy l do liczby
    inc     rsi

    cmp     [rsi], byte 0       ; sprawdź, czy koniec napisu
    jne     error               ; jeśli to nie koniec, to błąd 
%endmacro

%macro printString 2
    mov     eax, SYS_WRITE
    mov     rdi, STD_OUT
    mov     rsi, %1
    mov     rdx, %2
    syscall
%endmacro

%macro getInput 0
    mov     eax, SYS_READ
    mov     edi, STD_IN
    mov     rsi, buffer
    mov     rdx, BUFFER_SIZE
    syscall
%endmacro

_start:
    mov     r8, [rsp]       ; liczba argumentów
    cmp     r8, 5           ; 4 parametry + nazwa programu
    jne     error           ; zła liczba argumentów

    mov     r8, Linv
    checkParam 8 * 2        ; pierwszy arg (L)
    mov     r8, Rinv
    checkParam 8 * 3        ; drugi arg (R)
    mov     r8, Tinv
    checkParam 8 * 4        ; trzeci arg (T)
    ;checkKey               ; TODO
    ;getInput

    ; TODO szyfrowanie i wypisywanie bufora w while
    
    jmp exit

exit:                       ; zakończenie programu bez błędów
    mov     eax, SYS_EXIT
    xor     edi, edi        ; kod powrotu 0
    syscall

error:                      ; wyjście spowodowane złymi danymi
    mov     eax, SYS_EXIT
    mov     edi, 1          ; kod powrotu 1
    syscall