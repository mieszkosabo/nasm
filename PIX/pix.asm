;extern pixtime
extern printziom
global pix


section .text

%macro getDivFraction 2
  mov rdx, %1   ; argument do podzielenia
  xor eax, eax
  div %2        ; %2 to dzielnik, 64 bit register
  ; w rax mamy część "po przecinku"
%endmacro

%macro mulFractions 2
  mov rax, %1
  mul %2
  mov rax, rdx ; w rax mamy wynik (ew może być w rdx, zobaczymy)
%endmacro

%macro modPower 0
  mov    r8,rdx ; p do r8 wkładamy
  mov    rax,rdi ; x do rax'a, bo będziemy brać resztę z dzielenia
  xor    edx,edx ; zerujemy rdx
  div    r8      ; dzielimy przez p
  test   rdx,rdx ; w rdx mamy resztę z dzielenia, sprawdzamy czy niezerową
  mov    r9,rdx  ; przenosimy ją do r9
  je     %%exit  ; jeśli to zero to out
  test   rsi,rsi ; sprawdzamy czy y jest > 0
  je     %%one      ; jeśli mamy podnieść zioma do 0, outujemy
  mov    rcx,rdx ; przenosimy x do rcx
  mov    r9d,0x1 ; wkładamy 1 fo r9
  nop
%%odd:
  test   sil,0x1 ; sprawdzanie parzystości y-ka
  je     %%even 
  mov    rax,r9  ; jeśli y nieparzysty, to res = res * x
  xor    edx,edx
  imul   rax,rcx  ; mod p
  div    r8
  mov    r9,rdx
%%even:
  imul   rcx,rcx  ; y (już) parzyste, więc x = x^2 % p
  xor    edx,edx
  mov    rax,rcx
  div    r8
  shr    rsi,1    ; y = y / 2
  mov    rcx,rdx
  jne    %%odd
%%exit:
  mov    rax,r9
  jmp    %%end   
%%one:
  mov    r9d,0x1 
%%end:
%endmacro

; rdi ^ rsi % rdx, x ^ y % p
power:
  mov    r8,rdx ; p do r8 wkładamy
  mov    rax,rdi ; x do rax'a, bo będziemy brać resztę z dzielenia
  xor    edx,edx ; zerujemy rdx
  div    r8      ; dzielimy przez p
  test   rdx,rdx ; w rdx mamy resztę z dzielenia, sprawdzamy czy niezerową
  mov    r9,rdx  ; przenosimy ją do r9
  je     e1      ; jeśli to zero to out
  test   rsi,rsi ; sprawdzamy czy y jest > 0
  je     e8      ; jeśli mamy podnieść zioma do 0, outujemy
  mov    rcx,rdx ; przenosimy x do rcx
  mov    r9d,0x1 ; wkładamy 1 fo r9
  nop
b8:
  test   sil,0x1 ; sprawdzanie parzystości y-ka
  je     cd 
  mov    rax,r9  ; jeśli y nieparzysty, to res = res * x
  xor    edx,edx
  imul   rax,rcx  ; mod p
  div    r8
  mov    r9,rdx
cd:
  imul   rcx,rcx  ; y (już) parzyste, więc x = x^2 % p
  xor    edx,edx
  mov    rax,rcx
  div    r8
  shr    rsi,1    ; y = y / 2
  mov    rcx,rdx
  jne    b8
e1:
  mov    rax,r9
  ret    
  nop    
e8:
  mov    r9d,0x1
  jmp    e1 


cntCj:



pix:
  push rdi
  ; mov r13, 200546
  ; mov r8, 15
  ; mov rdx, 33
  mov rdi, 16
  mov rsi, 100
  mov rdx, 34
  ;modPower r13, r8, rdx
  modPower
  ;call power
  pop rdi
  ret
