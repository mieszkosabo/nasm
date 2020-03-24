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
    cmp     cl, dl          ; w cl znajduje się '1', a w al 'Z'
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
    mov r9, 49                  ; r9 będzie licznikiem
    %%loop:
        movzx   edx, byte [rsi] ; w rdx mamy znak z permutacji
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
        cmp     r9, 91          ; parametry L, R i T muszą mieć 42 znaki (42 + 49 = 91)
        jne     error
%endmacro

%macro  createInvKey 1
    mov %1, dl
    cmp %1, '1'
    je  %%else
    mov %1, 91
    sub %1, dl
    add %1, '1'
    %%else:
%endmacro

%macro  checkKey 0
    mov rsi, [rsp + 8 * 5]      ; umieszczamy w rsi wskaźnik do klucza
    mov cl, '1'                 ; akceptowane są znaki z przedziału
    mov al, 'Z'                 ; 1 - Z
    xor r12, r12                ; l
    xor r13, r13                ; r
    xor r14, r14                ; l'
    xor r15, r15                ; r'

    movzx   edx, byte [rsi]
    test    rdx, rdx            ; sprawdź, czy koniec napisu
    jz      error
    checkRange                  ; sprawdź, czy znak jest akceptowalnym zakresie
    mov     r12b, dl            ; przypisuję l na r12b
    createInvKey r14b           ; tworzę l'
    inc     rsi
    
    movzx   edx, byte [rsi]
    test    rdx, rdx            ; sprawdź, czy koniec napisu
    jz      error
    checkRange                  ; sprawdź, czy znak jest akceptowalnym zakresie
    mov     r13b, dl            ; przypisuję r na r13b
    createInvKey r15b           ; tworzę r'
    inc     rsi                 

    cmp     [rsi], byte 0       ; sprawdź, czy koniec napisu
    jne     error               ; jeśli to nie koniec, to błąd 
%endmacro

%macro printString 2
    mov     rsi, %1
    mov     rdx, %2
    mov     eax, SYS_WRITE
    mov     rdi, STD_OUT
    syscall
%endmacro

%macro getInput 0
    mov     eax, SYS_READ
    mov     edi, STD_IN
    mov     rsi, buffer
    mov     rdx, BUFFER_SIZE
    syscall
%endmacro

%macro Qperm 1
    add dl, %1
    sub dl, '1'             
    cmp dl, 'Z'
    jbe %%end                         ; mniejsze równe od 'Z', czyli ok
    sub dl, ALPHABET_SIZE             ; przesuwamy cyklicznie od początku naszego alfabetu

    %%end:
%endmacro

%macro Xperm 1
    mov rbx, %1                         ; w rbx mamy adres permutacji
    movzx edx, byte [rbx + rdx - '1']   ; wykonanie permutacji
%endmacro

%macro cypherBuff 0
    xor r9, r9                  ; index znaku w buforze
    mov cl, '1'                 ; akceptowane są znaki z przedziału
    mov al, 'Z'                 ; 1 - Z
    %%loop:
        movzx edx, byte [buffer + r9]  ; w rdx mamy znak do przepermutowania
        test rdx, rdx
        jz  %%return_from_cypher
        checkRange

        inc r13b                ; TODO omakrować to
        cmp r13b, 91             ; sprawdzamy, czy bębenek R nie wyszedł poza zakres
        jne %%else
        mov r13b, '1'
    %%else:                     ; r'
        dec r15b
        cmp r15b, '0'
        jne %%else2
        mov r15b, 'Z'
    %%else2:                    ; sprawdzamy czy R w pozycji obrotowej
        cmp r13b, 'L'
        je  %%incLRotor
        cmp r13b, 'R'
        je  %%incLRotor
        cmp r13b, 'T'
        jne %%cypherStart
    %%incLRotor:                ; jeśli R w obrotowej, to obracamy L
        inc r12b
        cmp r12b, 91             ; sprawdzamy, czy bębenek L nie wyszedł poza zakres
        jne %%else3
        mov r12b, '1'
    %%else3:
        dec r14b
        cmp r14b, '0'
        jne %%cypherStart
        mov r14b, 'Z'
    %%cypherStart:
        Qperm r13b          ; Qr
        Xperm [rsp + 8 * 3] ; R
        Qperm r15b          ; Qr^-1

        Qperm r12b          ; Ql
        Xperm [rsp + 8 * 2] ; L
        Qperm r14b          ; Ql^-1

        Xperm [rsp + 8 * 4] ; T

        Qperm r12b          ; Ql
        Xperm Linv          ; Linv
        Qperm r14b          ; Ql^-1

        Qperm r13b          ; Qr
        Xperm Rinv          ; Rinv
        Qperm r15b          ; Qr^-1

        mov [buffer + r9], dl
        inc r9
        jmp %%loop
    %%return_from_cypher:
    ; wychodzimy z pętli
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
    checkKey 
        
reading:
    getInput                ; w rax mamy liczbę wczytanych bajtów
    test rax, rax           ; sprawdzamy, czy EOF
    jz  exit                ; jak tak, to koniec danych
    cypherBuff
    printString buffer, rax
    jmp reading

exit:                       ; zakończenie programu bez błędów
    mov     eax, SYS_EXIT
    xor     edi, edi        ; kod powrotu 0
    syscall

error:                      ; wyjście spowodowane złymi danymi
    mov     eax, SYS_EXIT
    mov     edi, 1          ; kod powrotu 1
    syscall

error2:                      ; wyjście spowodowane złymi danymi
    mov     eax, SYS_EXIT
    mov     edi, 3          ; kod powrotu 3
    syscall