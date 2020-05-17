extern pixtime
global pix

section .text

; first argument gets divided by second; fractional part ends up in rax
%macro divFra 2
  mov     rdx, %1                     
  xor     eax, eax
  div     %2                          
%endmacro
; multiplies two fractions; result in rax
%macro mulFra 2
  mov     rax, %1
  mul     %2
%endmacro

; computes x^y % p, where x, y, p are in rax, rsi and r8; result in rax
%macro modPower 0
  mov     r12, rsi                    ; y <- n-k
  test    r12,r12                     ; check if y > 0
  je      %%one                       
  xor     edx,edx 
  div     r8                          ; divide by p
  test    rdx,rdx                     ; check if remeinder is > 0
  mov     r9,rdx  
  je      %%exit                      ; if (x % p == 0) return 0
  
  mov     rdi,rdx                     ; move x to rdi
  mov     r9d,0x1                     
  nop
%%odd:
  test    r12b,0x1                    ; check if y is even
  je      %%even 
  mov     rax,r9                      ; if y is odd, then res = res * x
  xor     edx,edx
  imul    rax,rdi                     ; mod p
  div     r8
  mov     r9,rdx
%%even:
  imul    rdi,rdi                     ; if y is even, then x = x^2 % p
  xor     edx,edx
  mov     rax,rdi
  div     r8
  shr     r12,1                       ; y = y / 2
  mov     rdi,rdx
  jne     %%odd
%%exit:
  mov     rax,r9
  jmp     %%end   
%%one:
  mov     rax, 0x1                    ; x^0 % p = if p == 1 then 0 else 1
  xor     edi, edi
  cmp     r8, 1 
  cmove   eax, edi     
%%end:
%endmacro

; first arg is j, second n
cntSj:
  mov     r11, rdi                    ; put j in r11
  xor     ebp, ebp                    ; k = 0, counter
  mov     r8, rdi
  xor     r10, r10                    ; result in r13
loop:
  mov     rax, 16                     ; const
  modPower      
  divFra  rax, r8                     ; result in rax
  add     r10, rax                    ; res += fraction
  add     rbp, 1                      ; k++
  mov     r8, rbp                     ; r8 = k
  shl     r8, 3                       ; r8 = 8*k
  add     r8, r11                     ; r8 = 8*k+j
  sub     rsi, 1                      ; n-k
  cmp     rbp, rcx                    ; cmp k with n
  jbe     loop

  mov     rsi, 0x1000000000000000     ; {1/16}
  mov     r12, rsi                    ; r12 - 16 raised to folowing powers
loop2:
  mov     rax, r12  
  xor     rdx, rdx
  div     r8                          ; current power of 16 / 8k+j
  test    rax, rax
  jz      end
  add     r10, rax                    ; res += curPart
  xor     rdx, rdx
  mulFra  r12, rsi
  mov     r12, rdx                    
  add     rbp, 1                      ; k++
  mov     r8, rbp                     ; r8 = k
  shl     r8, 3                       ; r8 = 8*k
  add     r8, r11                     ; r8 = 8*k+j
  jmp     loop2
end:
  mov     rax, r10
  ret

; n is a parameter here
%macro BBP 1
  mov     rdi, 1
  mov     rsi, %1
  call    cntSj
  lea     rbx, [rax+rax*1]

  mov     rdi, 4
  mov     rsi, %1
  call    cntSj
  sub     rbx, rax
  add     rbx, rbx

  mov     rdi, 5
  mov     rsi, %1
  call    cntSj
  sub     rbx, rax

  mov     rdi, 6
  mov     rsi, %1
  call    cntSj
  sub     rbx, rax
%endmacro

%macro pushRegs 0
  push    rbx
  push    rbp
  push    r12
  push    r13
  push    r14
  push    r15
%endmacro

%macro popRegs 0
  pop     r15
  pop     r14
  pop     r13
  pop     r12
  pop     rbp
  pop     rbx
%endmacro

%macro ptime 0
  rdtsc
  mov     rdi, rdx
  shl     rdi, 32
  add     rdi, rax
  call pixtime
%endmacro

pix:
  sub rsp, 0x8
  pushRegs
  mov     r15, rdx                    ; max in r15
  mov     r14, rsi                    ; &pid in r14
  mov     r13, rdi                    ; array ptr in r13
  ptime
  mov     rcx, 1
  lock \
  xadd    [r14], rcx
  cmp     rcx, r15
  jae     finish
repeat:
  lea     rcx, [rcx*8+0x0]            ; rcx = 8*m
  BBP     rcx                         ; 64 bit result in rbx
  shr     rbx, 32                     ; rbx >> 32
  shr     rcx, 1
  mov     dword[r13 + rcx], ebx
  mov     rcx, 1
  lock \
  xadd    [r14], rcx
  cmp     rcx, r15
  jb      repeat
finish:
  ptime
  xor     eax, eax
  popRegs
  add rsp, 0x8
  ret
