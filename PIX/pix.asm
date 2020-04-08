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
  ;mov rax, rdx ; w rax mamy wynik (ew może być w rdx, zobaczymy)
%endmacro

%macro modPower 0
  ;mov    r8,rdx ; p do r8 wkładamy
  ;mov    rax,rdi ; x do rax'a, bo będziemy brać resztę z dzielenia
  mov    r12, rsi ; y <- n-k
  xor    edx,edx ; zerujemy rdx
  div    r8      ; dzielimy przez p
  test   rdx,rdx ; w rdx mamy resztę z dzielenia, sprawdzamy czy niezerową
  mov    r9,rdx  ; przenosimy ją do r9
  je     %%exit  ; jeśli to zero to out
  test   r12,r12 ; sprawdzamy czy y jest > 0
  je     %%one      ; jeśli mamy podnieść zioma do 0, outujemy
  mov    rcx,rdx ; przenosimy x do rcx
  mov    r9d,0x1 ; wkładamy 1 fo r9
  nop
%%odd:
  test   r12b,0x1 ; sprawdzanie parzystości y-ka
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
  shr    r12,1    ; y = y / 2
  mov    rcx,rdx
  jne    %%odd
%%exit:
  mov    rax,r9
  jmp    %%end   
%%one:
  mov    rax,0x1 
%%end:
%endmacro

; first arg is j, second n
cntCj:
  mov r15, rdi ; j do r15
  xor ebp, ebp
  mov r14, rsi ; n do r14
  mov r8, rdi
  xor r13, r13 ; miejsce na wynik
loop:
  mov rax, 16 ; stała do podniesienia do potęgi
  modPower      ; w rax jest numerator
  getDivFraction rax, r8 ; wynik w rax
  add r13, rax  ; res += fraction
  add rbp, 1    ; k++
  mov r8, rbp   ; r8 = k
  shl r8, 3     ; r8 = 8*k
  add r8, r15   ; r8 = 8*k+j
  sub rsi, 1    ; n-k
  cmp rbp, r14  ; cmp k with n
  jbe loop

  mov rdi, 0x1000000000000000 ; {1/16}
  mov r12, rdi ; currPow i num
loop2:
  mov rax, r12  ; do num wkładam curPow
  xor rdx, rdx
  div r8        ; curPow / 8k+j
  test rax, rax
  jz end
  add r13, rax  ; res += curPart
  xor rdx, rdx
  mulFractions r12, rdi
  mov r12, rdx ; przenoszę wynik do r12
  add rbp, 1    ; k++
  mov r8, rbp   ; r8 = k
  shl r8, 3     ; r8 = 8*k
  add r8, r15   ; r8 = 8*k+j
  jmp loop2
end:
  mov rax, r13
  ret

; n is parameter
%macro BBP 1

  mov rdi, 1
  mov rsi, %1
  call cntCj
  mov rbx, rax
  shl rbx, 2

  mov rdi, 4
  mov rsi, %1
  call cntCj

  mov rdi, 5
  mov rsi, %1
  call cntCj

  mov rdi, 6
  mov rsi, %1
  call cntCj

%endmacro

pix:
  push rdi
  mov rdi, 1
  mov rsi, 5
  call cntCj
  pop rdi
  ret
