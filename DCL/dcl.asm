SYS_WRITE       equ 1
SYS_EXIT        equ 60
STD_OUT         equ 1
ALPHABET_SIZE   equ 42  
BUFFER_SIZE     equ 4096

global _start

section .bss
  buffer  resb    BUFFER_SIZE
  InvPerm resb    128

section .text

; Checks whether T consists of 21 2-cycles, by checking for
; 1-cycles and if T(T(x)) == x.
%macro checkT 0
  mov     rbx, [rsp + 8 * 4]          ; put address pointing to T in rbx
  mov     dl, '1'                     ; we go through our alphabet 
%%loop:
  cmp     dl, 91                      ; 90 is the last letter ('Z')
  je      %%endloop
  movzx   r8, byte [rbx + rdx - '1']  ; r8 = T(dl)
  cmp     r8b, dl                     ; T(x) == x?
  je      error                       ; 1-cycles are forbidden
  movzx   r8, byte [rbx + r8 - '1']
  cmp     r8b, dl                     ; T(T(x)) == x?
  jne     error

  inc     dl
  jmp     %%loop
%%endloop:
%endmacro

; Veryfies whether l or r is a correct key and creates
; a 'inverse key' to it: l' or r'. These dash keys are used
; for inverse cyclic shift (Q^-1). I store l, r, l' and r'
; in  r12, r13, r14 and r15 registers.
%macro checkKey 1
  movzx   edx, byte [rsi]
  test    rdx, rdx                    ; checks for unexpected null byte
  jz      error
  call    checkRange          
  mov     %1, rdx            
  sub     %1, '1'                 
  inc     rsi                 
%endmacro

%macro  checkKeys 0
  mov     rsi, [rsp + 8 * 5]          ; put pointer to key in rsi                
  checkKey r12
  checkKey r13
  cmp     [rsi], byte 0       
  jne     error                       ; if it isn't the end then key is invalid 
%endmacro

%macro print 2
  mov     rsi, %1
  mov     rdx, %2
  mov     eax, SYS_WRITE
  mov     rdi, STD_OUT
  syscall
%endmacro

%macro read 0
  xor     eax, eax
  xor     edi, edi
  mov     rsi, buffer
  mov     rdx, BUFFER_SIZE
  syscall
%endmacro

%macro Xperm 1
  mov     rbx, %1                     ; put permutation addresss in rbx
  movzx   edx, byte [rbx + rdx - '1'] ; permutate letter in rdx
%endmacro

; Performs a cyclic shift of a letter in dl.
%macro Q 1
  add     rdx, %1                     ; x += r (or l)
  mov     eax, edx                    
  sub     eax, 42                     ; y = x + r - 42
  cmp     eax, '1'
  cmovge  edx, eax                    ; if x out of range -> x = y
%endmacro

%macro QInv 1
  sub     rdx, %1
  mov     eax, edx
  add     eax, 42
  cmp     eax, 'Z'
  cmovbe  edx, eax
%endmacro

; This macro cyphers consequtive buffer letters until reaches a null byte.
; It also shifts rotors and checks if input is valid. 
%macro cypher 0
  xor     r9, r9                      ; letter index in buffer              
%%loop:
  cmp     r9, r10                     ; compare with no. of read bytes
  je      %%end
  movzx   edx, byte [buffer + r9]     ; put letter to permutate in rdx
  
  cmp     dl, '1'                     ; check range       
  jb      error           
  cmp     dl, 'Z'
  ja      error 
  
  xor     eax, eax                    ; eax will be used for comparison with 0
  add     r13, 1                      ; shift rotor R
  cmp     r13, 42                     ; check if out of range (91 = 'Z' + 1)
  cmove   r13, rax                    ; shift R to beginning
  cmp     r13, 'L' - '1'              ; check if in turnover position
  je      %%incLRotor
  cmp     r13, 'R' - '1'
  je      %%incLRotor
  cmp     r13, 'T' - '1'
  je      %%incLRotor

  %%start:
  Q       r13                         ; Qr(x)
  Xperm   [rsp + 8 * 3]               ; R(x)
  QInv    r13                         ; Qr^-1(x)

  Q       r12                         ; Ql(x)
  Xperm   [rsp + 8 * 2]               ; L(x)
  QInv    r12                         ; Ql^-1(x)

  Xperm   [rsp + 8 * 4]               ; T(x)

  lea     r8, [InvPerm]               ; put pointer to inverse permutations in r8
  Q       r12                         ; Ql
  Xperm   r8                          ; L^-1(x)
  QInv    r12                         ; Ql^-1(x)

  add     r8, ALPHABET_SIZE           ; move pointer from L^-1 to R^-1
  Q       r13                         ; Qr
  Xperm   r8                          ; R^-1
  QInv    r13                         ; Qr^-1

  mov     [buffer + r9], dl
  add     r9, 1
  jmp     %%loop
%%incLRotor:                          ; shifts rotor L
  add     r12, 1
  cmp     r12, 42
  cmove   r12, rax
  jmp     %%start
%%end:
%endmacro

_start:
  mov     r8, [rsp]                   ; number of arguments
  cmp     r8, 5                       ; 4 parameters + program name
  jne     error                       

  xor     al, al                      ; fill memory alocated for inverse
  mov     ecx, 126                    ; permutations with 0s
  lea     rdi, [InvPerm]
  rep     stosb

  lea     r8, [InvPerm]
  lea     rbp, [rsp + 16]
  call    checkParam                  ; first parameter (L)
  add     r8, ALPHABET_SIZE
  add     rbp, 8
  call    checkParam                  ; second parameter (R)
  add     rbp, 8
  add     r8, ALPHABET_SIZE
  call    checkParam                  ; third parameter (T)
  checkT
  checkKeys                
        
reading:
  read                                ; syscall puts no. of bytes in rax
  mov     r10, rax
  test    rax, rax                    ; check if EOF
  jz      exit                        
  cypher
  print   buffer, r10                 ; r9 counts input in cypher macro
  jmp     reading

exit:                                 ; end program with success
  mov     eax, SYS_EXIT
  xor     edi, edi                    ; exit code 0
  syscall

error:                                ; end program due to invalid input
  mov     eax, SYS_EXIT
  mov     edi, 1                      ; exit code 1
  syscall

; This procedure validates parameters and creates inverse permutations.
; Permutation to validate should be in rbp.
; Puts inverse permutation in r8.
checkParam:
  mov     rsi, [rbp]                  ; put string in rsi                    
  mov     r9, 49                      ; use r9 as counter
loop:
  movzx   edx, byte [rsi]             ; put next character from permutation
  test    rdx, rdx                    ; check if end of string
  jz      return_from_check
  call    checkRange                 
  cmp     byte [r8 + rdx - '1'], 0    ; permutation must be 1-1
  jne     error               
  mov     [r8 + rdx - '1'], r9b       ; Inv['z'] = counter++;
  inc     r9                  
  inc     rsi
  jmp     loop
return_from_check:
  cmp     r9, 91                      ; L, R and T must consist of 
  jne     error                       ; 42 chars (42 + 49 = 91)
  ret

; Checks if letter in dl is between '1' and 'Z'.
checkRange:
  cmp     dl, '1'          
  jb      error           
  cmp     dl, 'Z'
  ja      error           
  ret
