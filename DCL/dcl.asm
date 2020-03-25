SYS_WRITE   equ 1
SYS_EXIT    equ 60
SYS_READ    equ 0
STD_IN      equ 0
STD_OUT     equ 1
ALPHABET_SIZE   equ 42  
BUFFER_SIZE equ 4096

global _start

section .bss
    buffer  resb    BUFFER_SIZE
    InvPerm resb    126

section .text

%macro fillInvsWithZeros 0
    xor al, al
    mov ecx, 126
    lea rdi, [InvPerm]
    rep stosb
%endmacro

%macro checkT 0
    mov rbx, [rsp + 8 * 4]
    mov dl, '1' 
    %%loop:
        cmp dl, 91
        je %%endloop
        movzx r8, byte [rbx + rdx - '1']
        cmp r8b, dl
        je error
        movzx r8, byte [rbx + r8 - '1']
        cmp r8b, dl
        jne error

        inc dl
        jmp %%loop
    %%endloop:
%endmacro

%macro verifySingleKey 2
    movzx   edx, byte [rsi]
    test    rdx, rdx            ; sprawdź, czy koniec napisu
    jz      error
    call checkRange                  ; sprawdź, czy znak jest akceptowalnym zakresie
    mov     %1, dl              ; przypisuję l na r12b, r na r13b, l' na r14b
    call createInvKey            ; i r' na r15b
    mov %2, r8b                 ; 'klucz odwrotny' znajduje się w r8b po wywołaniu
    inc     rsi                 ; createInvKey
%endmacro

%macro  checkKey 0
    mov rsi, [rsp + 8 * 5]      ; umieszczamy w rsi wskaźnik do klucza
    mov cl, '1'                 ; akceptowane są znaki z przedziału
    mov al, 'Z'                 ; 1 - Z
    verifySingleKey r12b, r14b
    verifySingleKey r13b, r15b
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

%macro Xperm 1
    mov rbx, %1                         ; w rbx mamy adres permutacji
    movzx edx, byte [rbx + rdx - '1']   ; wykonanie permutacji w rdx
%endmacro

%macro cypherBuff 0
    xor r9, r9                  ; index znaku w buforze
    mov cl, '1'                 ; akceptowane są znaki z przedziału
    mov al, 'Z'                 ; 1 - Z
    %%loop:
        movzx edx, byte [buffer + r9]  ; w rdx mamy znak do przepermutowania
        test rdx, rdx
        jz  %%return_from_cypher
        call checkRange

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
        mov bpl, r13b
        call Qperm          ; Qr
        Xperm [rsp + 8 * 3] ; R
        mov bpl, r15b
        call Qperm          ; Qr^-1

        mov bpl, r12b
        call Qperm          ; Ql
        Xperm [rsp + 8 * 2] ; L
        mov bpl, r14b
        call Qperm          ; Ql^-1

        Xperm [rsp + 8 * 4] ; T

        lea r8, [InvPerm]     ; przenoszę wskaźnik do odwrotnych permutacji do r8
        mov bpl, r12b
        call Qperm          ; Ql
        Xperm r8          ; L^-1
        mov bpl, r14b
        call Qperm          ; Ql^-1

        add r8, 42          ; przesuwam wskaźnik z L^-1 na R^-1
        mov bpl, r13b
        call Qperm          ; Qr
        Xperm r8          ; R^-1
        mov bpl, r15b
        call Qperm          ; Qr^-1

        mov [buffer + r9], dl
        inc r9
        jmp %%loop
    %%return_from_cypher:
%endmacro

_start:
    mov     r8, [rsp]       ; liczba argumentów
    cmp     r8, 5           ; 4 parametry + nazwa programu
    jne     error           ; zła liczba argumentów
    fillInvsWithZeros
    
    lea     r8, [InvPerm]
    lea     rbp, [rsp + 16]
    call    checkParam      ; pierwszy arg (L)
    add     r8, 42
    add     rbp, 8
    call    checkParam      ; drugi arg (R)
    add     rbp, 8
    add     r8, 42
    call    checkParam      ; trzeci arg (T)
    checkT
    checkKey                
        
reading:
    getInput                ; w rax mamy liczbę wczytanych bajtów
    test rax, rax           ; sprawdzamy, czy EOF
    jz  exit                ; jak tak, to koniec danych
    cypherBuff
    printString buffer, r9
    jmp reading

exit:                       ; zakończenie programu bez błędów
    mov     eax, SYS_EXIT
    xor     edi, edi        ; kod powrotu 0
    syscall

error:                      ; wyjście spowodowane złymi danymi
    mov     eax, SYS_EXIT
    mov     edi, 1          ; kod powrotu 1
    syscall

checkParam:
    mov rsi, [rbp]         ; przenosimy odpowiedni napis do rsi
    mov cl, '1'                 ; akceptowane są znaki z przedziału
    mov al, 'Z'                 ; 1 - Z
    mov r9, 49                  ; r9 będzie licznikiem
loop:
    movzx   edx, byte [rsi]     ; w rdx mamy znak z permutacji
    test    rdx, rdx            ; sprawdź, czy koniec napisu
    jz return_from_check
    call checkRange                  ; sprawdź, czy znak jestw akceptowalnym zakresie
    cmp byte [r8 + rdx - '1'], 0 ; sprawdź, czy nie pojawił się ten znak już
    jne     error               ; jeśli się pojawił, to nie jest permutacja
    mov [r8 + rdx - '1'], r9b   ; Inv['z'] = licznik++;
    inc     r9                  ; TODO inv może też być + '1'?
    inc     rsi
    jmp     loop
return_from_check:
    cmp     r9, 91              ; parametry L, R i T muszą mieć 42 znaki (42 + 49 = 91)
    jne     error
    ret


checkRange:
    cmp     cl, dl          ; w cl znajduje się '1', a w al 'Z'
    ja      error           ; '1' > znak
    cmp     dl, al
    ja      error           ; znak > 'Z'
    ret


Qperm:
    add dl, bpl
    sub dl, '1'
    cmp dl, 'Z'
    jbe end
    sub dl, ALPHABET_SIZE
end:
    ret

createInvKey:
    mov r8b, dl
    cmp r8b, '1'
    je  else
    mov r8b, 91
    sub r8b, dl
    add r8b, '1'
else:
    ret
