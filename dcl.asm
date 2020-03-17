SYS_WRITE   equ 1
SYS_EXIT    equ 60
SYS_READ    equ 0
STD_IN      equ 0
STD_OUT     equ 1
ALPHABET_SIZE   equ 42
BUFFER_SIZE equ 4096

global _start

section .rodata
    NEWLINE db  `\n`

section .bss
    buffer  resb    BUFFER_SIZE
    L       resb    42
    R       resb    42
    T       resb    42
    l       resb    1
    r       resb    1

section .text

%macro checkRange 0
    cmp     cl, [rsi]       
    ja      error           ; '1' > literka
    cmp     [rsi], al
    ja      error           ; literka > 'Z'
%endmacro

; sprawdza, czy w rsi jest poprawny parametr L, R lub T.
; parametrem jest przesunięcie względem rsp - wskaźnik do parametru
%macro  checkParam 1
    mov rsi, [rsp + %1]         ; przenosimy odpowiedni napis do rsi
    mov cl, '1'                 ; akceptowane są znaki z przedziału
    mov al, 'Z'                 ; 1 - Z
    %%loop:
        cmp     [rsi], byte 0   ; sprawdź, czy koniec napisu
        je %%return_from_check
        checkRange              ; sprawdź, czy znak jestw akceptowalnym zakresie
        sub byte [rsi], '1'        ; normalizujemy do liczb od 0 do 41
        inc     rsi
        jmp     %%loop
    %%return_from_check:
        sub     rsi, [rsp + %1] ; oblicz długośc wczytanego napisu
        cmp     rsi, 3          ; parametry L, R i T muszą mieć 42 znaki ;TODO zminić na 42
        jne     error
        mov rsi, [rsp + %1]
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

    checkParam 8 * 2        ; pierwszy arg (L)
    mov     [L], rsi
    checkParam 8 * 3        ; drugi arg (R)
    mov     [R], rsi
    checkParam 8 * 4        ; trzeci arg (T)
    mov     [T], rsi
    checkKey
    getInput
    
    ;sub byte    [L], 49
    xor r8, r8
    mov     r8b, [buffer]
    cmp  byte   [L], 0
    je      error
    sub     r8b, [L]
    mov     [buffer], r8b
    ;sub    [buffer], [r8b]
    printString buffer, 1
    printString NEWLINE, 1
    jmp exit

exit:                       ; zakończenie programu bez błędów
    mov     eax, SYS_EXIT
    xor     edi, edi        ; kod powrotu 0
    syscall

error:                      ; wyjście spowodowane złymi danymi
    mov     eax, SYS_EXIT
    mov     edi, 1          ; kod powrotu 1
    syscall