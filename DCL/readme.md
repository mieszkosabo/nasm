compile with
```
nasm -f elf64 -w+all -w+error -o dcl.o dcl.asm && ld --fatal-warnings -o dcl dcl.o

```
