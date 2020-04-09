;extern pixtime
;extern printziom
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
%endmacro

%macro modPower 0
  mov    r12, rsi ; y <- n-k
  test   r12,r12 ; sprawdzamy czy y jest > 0
  je     %%one   ; jeśli mamy podnieść zioma do 0, outujemy z res 1
  xor    edx,edx ; zerujemy rdx
  div    r8      ; dzielimy przez p
  test   rdx,rdx ; w rdx mamy resztę z dzielenia, sprawdzamy czy niezerową
  mov    r9,rdx  ; przenosimy ją do r9
  je     %%exit  ; jeśli to zero to out
  
  mov    rdi,rdx ; przenosimy x do (rdi)
  mov    r9d,0x1 ; wkładamy 1 fo r9
  nop
%%odd:
  test   r12b,0x1 ; sprawdzanie parzystości y-ka
  je     %%even 
  mov    rax,r9  ; jeśli y nieparzysty, to res = res * x
  xor    edx,edx
  imul   rax,rdi  ; mod p
  div    r8
  mov    r9,rdx
%%even:
  imul   rdi,rdi  ; y (już) parzyste, więc x = x^2 % p
  xor    edx,edx
  mov    rax,rdi
  div    r8
  shr    r12,1    ; y = y / 2
  mov    rdi,rdx
  jne    %%odd
%%exit:
  mov    rax,r9
  jmp    %%end   
%%one:
  mov    rax, 0x1
  xor    edi, edi
  cmp    r8, 1 
  cmove  eax, edi     
%%end:
%endmacro

; first arg is j, second n
cntCj:
  push r8
  mov r15, rdi ; j do r15
  xor ebp, ebp ; k = 0, licznik
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

  mov rsi, 0x1000000000000000 ; {1/16}
  mov r12, rsi ; currPow i num
loop2:
  mov rax, r12  ; do num wkładam curPow
  xor rdx, rdx
  div r8        ; curPow / 8k+j
  test rax, rax
  jz end
  add r13, rax  ; res += curPart
  xor rdx, rdx
  mulFractions r12, rsi
  mov r12, rdx ; przenoszę wynik do r12
  add rbp, 1    ; k++
  mov r8, rbp   ; r8 = k
  shl r8, 3     ; r8 = 8*k
  add r8, r15   ; r8 = 8*k+j
  jmp loop2
end:
  mov rax, r13
  pop r8
  ret

; n is parameter
%macro BBP 1
  mov rdi, 1
  mov rsi, %1
  call cntCj
  lea rbx, [rax+rax*1]

  mov rdi, 4
  mov rsi, %1
  call cntCj
  sub rbx, rax
  add rbx, rbx

  mov rdi, 5
  mov rsi, %1
  call cntCj
  sub rbx, rax

  mov rdi, 6
  mov rsi, %1
  call cntCj
  sub rbx, rax
%endmacro

%macro pushRegs 0
  push rbx
  push rbp
  push r12
  push r13
  push r14
  push r15
%endmacro

%macro popRegs 0
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbp
  pop rbx
%endmacro

pix:
  pushRegs
  mov r11, rdx    ; max na r11
  mov rcx, [rsi]  ; rcx to m
  mov r10, rdi    ; tablica na r10
repeat:
  lea r8, [rcx*8+0x0] ; r8 = 8*m
  BBP r8        ; w rbx pojawia się 64 bit wynik
  shr rbx, 32   ; rbx >> 32, starsze 32 bity na ebx
  mov dword[r10 + rcx*4], ebx
  add rcx, 1    ; m++
  cmp rcx, r11
  jb  repeat

  xor eax, eax
  popRegs
  ret
