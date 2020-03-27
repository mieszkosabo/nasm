TODO:
- change if else branches so that the most common path doesnt require conditional jumps. (the one w/out shifting r)
- Avoid address size prefixes. Avoid operand size prefixes on instructions with an immediate operand. For example, it is preferred to replace MOV AX,2 by MOV EAX,2.
- avoid long dependency chains
- instead xor ax, ax => xor eax, eax (breaking dependencies)
- copy loop/function epilogs to eliminate unconditional jumps
- 
