section .text
    global _start
    extern _start_readFile  ; Declare _start_readFile as an external symbol

_start:
    ; Call the _start_readFile function in readFile.s
    call _start_readFile

    ; Exit the program
    mov rax, 60             ; syscall number for sys_exit
    xor rdi, rdi            ; return 0
    syscall
