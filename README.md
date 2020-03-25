# nasm
My programs written in NASM during Operating Systems course.

# extremely helpful links

- [x86_64 NASM Assembly register names](https://www.cs.uaf.edu/2017/fall/cs301/reference/x86_64.html)
- [huge list of instructions with detailed descriptions](https://c9x.me/x86/?fbclid=IwAR31tHS6P_aFyGEeYtsVvBVm8VMk0osdNss8i36Dpo7E4KW8U4Vi49UAmpo)
- [which regesters are safe from being modified by syscalls](https://i.stack.imgur.com/WgcQv.png)
- [syscalls](http://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)

### DCL

todo ocb
compile with
```
nasm -f elf64 -w+all -w+error -o dcl.o dcl.asm && ld --fatal-warnings -o dcl dcl.o

```

### PIX

todo ocb



