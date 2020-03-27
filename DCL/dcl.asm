SYS_WRITE       equ 1
SYS_EXIT        equ 60
SYS_READ        equ 0
STD_IN          equ 0
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
%macro checkKey 2
  movzx   edx, byte [rsi]
  test    rdx, rdx                    ; checks for unexpected null byte
  jz      error
  call    checkRange          
  mov     %1, dl              
  call    createInvKey                ; return value of createInvKey is in r8 
  mov %2, r8b                 
  inc     rsi                 
%endmacro

%macro  checkKeys 0
  mov     rsi, [rsp + 8 * 5]          ; put pointer to key in rsi                
  checkKey r12b, r14b
  checkKey r13b, r15b
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

; This macro cyphers consequtive buffer letters until reaches a null byte.
; It also shifts rotors and checks if input is valid. 
%macro cypher 0
  xor     r9, r9                      ; letter index in buffer              
%%loop:
  movzx   edx, byte [buffer + r9]     ; put letter to permutate in rdx
  call    checkRange
  call    moveRotors
  %%start:
  mov     bpl, r13b                   ; put arguments for Qperm in bpl
  call    Qperm                       ; Qr(x)
  Xperm   [rsp + 8 * 3]               ; R(x)
  mov     bpl, r15b
  call    Qperm                       ; Qr^-1(x)

  mov     bpl, r12b
  call    Qperm                       ; Ql(x)
  Xperm   [rsp + 8 * 2]               ; L(x)
  mov     bpl, r14b
  call    Qperm                       ; Ql^-1(x)

  Xperm   [rsp + 8 * 4]               ; T(x)

  lea     r8, [InvPerm]               ; put pointer to inverse permutations in r8
  mov     bpl, r12b
  call    Qperm                       ; Ql
  Xperm   r8                          ; L^-1(x)
  mov     bpl, r14b
  call    Qperm                       ; Ql^-1(x)

  add     r8, ALPHABET_SIZE           ; move pointer from L^-1 to R^-1
  mov     bpl, r13b
  call    Qperm                       ; Qr
  Xperm   r8                          ; R^-1
  mov     bpl, r15b
  call    Qperm                       ; Qr^-1

  mov     [buffer + r9], dl
  add     r9, 1
  cmp     r9, r10                     ; compare with no. of read bytes
  jne     %%loop
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

moveRotors:
  add     r13, 1                      ; shift rotor R
  sub     r15, 1                      ; now, shift r'
  cmp     r13b, 'Z' + 1               ; check if out of range (91 = 'Z' + 1)
  je      shiftR ;shiftR
  cmp     r15b, '0' ; check r'
  je      shiftRdash ; ShiftR'
  cmp     r13b, 'L'   ; czekujemy poz obrotową
  je      incLRotor
  cmp     r13b, 'R'
  je      incLRotor
  cmp     r13b, 'T'
  je      incLRotor
  ret
shiftR:
  mov     r13b, '1'                   ; shift r to beginning
  ret
shiftRdash:                     
  mov     r15b, 'Z'
  ret
incLRotor:                          ; if it is, then shift rotor L
  add     r12, 1  ; l++
  sub     r14, 1  ; l'--
  cmp     r12b, 'Z' + 1             
  jne     else3
  mov     r12b, '1'
else3:                              
  cmp     r14b, '0'
  jne     else4
  mov     r14b, 'Z'
else4:
  ret

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

; Checks if letter in dl is between letters in cl and al.
checkRange:
  cmp     dl, '1'          
  jb      error           
  cmp     dl, 'Z'
  ja      error           
  ret

; Arguments (r, l, r' or l') should be in bpl.
; Performs a cyclic shift of a letter in dl.
Qperm:
  add     dl, bpl
  ;sub     dl, '1'
  cmp     dl, 'Z'
  jbe     end
  sub     dl, ALPHABET_SIZE
end:
  ret

; Creates l' or r' and puts it r8b.
; Arguments (l or r) should be in dl.
createInvKey:
  mov     r8b, dl
  cmp     r8b, '1'
  je      else
  mov     r8b, 91
  sub     r8b, dl
  add     r8b, '1'
else:
  ret