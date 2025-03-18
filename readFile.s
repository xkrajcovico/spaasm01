section .data
    filename db 'ahoj.txt', 0
    start_delimiter db ' ----- start of the file', 0
    end_delimiter db '----- end of the file', 0
    first_null db '000', 0
    newline db 0xA, 0       ; Single newline character
    line_number db 1         ; Initialize line number to 1 (binary, not ASCII)
    ascii_buffer db '000 ', 0 ; Buffer to store ASCII representation of line number + space

section .bss
    buffer resb 1           ; Buffer to store the current character
    file_descriptor resq 1  ; Reserve space for a 64-bit file descriptor

section .text
    global _start_readFile
_start_readFile:
    ; Open the file
    mov rax, 2              ; syscall number for sys_open
    mov rdi, filename       ; filename
    mov rsi, 0              ; read-only mode
    mov rdx, 0              ; no special flags
    syscall
    mov [file_descriptor], rax  ; Save the file descriptor

    cmp rax, 0
    jl exit                 ; If opening failed, exit
    
    ; Print 000
    mov rax, 1              ; syscall number for sys_write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, first_null      ; address of string
    mov rdx, 3              ; length of "000" (without trailing newline)
    syscall

    ; Print start delimiter immediately after "000"
    mov rax, 1              ; syscall number for sys_write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, start_delimiter ; address of start delimiter
    mov rdx, 24             ; length of "start of the file" (17 characters)
    syscall

    ; Print newline after the start delimiter
    mov rax, 1              ; syscall number for sys_write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, newline        ; address of newline
    mov rdx, 1              ; number of bytes to write
    syscall

read_loop:
    ; Convert line number to ASCII
    call convert_line_number_to_ascii

    ; Print line number at the start of each line
    mov rax, 1              ; syscall number for sys_write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, ascii_buffer   ; address of ASCII line number + space
    mov rdx, 4              ; number of bytes to write (3 digits + 1 space)
    syscall

line_content:
    ; Read from file
    mov rax, 0              ; syscall number for sys_read
    mov rdi, [file_descriptor]  ; file descriptor
    mov rsi, buffer         ; buffer to store read data
    mov rdx, 1              ; number of bytes to read (1 byte at a time)
    syscall

    cmp rax, 0
    je end_print            ; If EOF, skip printing newline before delimiter

    ; Write the read character to stdout
    mov rax, 1              ; syscall number for sys_write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, buffer         ; address of buffer
    mov rdx, 1              ; number of bytes to write
    syscall

    ; Check if the read character is a newline
    cmp byte [buffer], 0xA
    jne line_content        ; If not a newline, continue reading the line

    ; Increment line number
    inc byte [line_number]

    ; Continue to the next line
    jmp read_loop

end_print:
    ; Print the end delimiter after file content
    mov rax, 1              ; syscall number for sys_write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, end_delimiter  ; address of end delimiter
    mov rdx, 21             ; length of "end of the file" (15 characters)
    syscall

    ; Print a single newline after the end delimiter
    mov rax, 1              ; syscall number for sys_write
    mov rdi, 1              ; file descriptor (stdout)
    mov rsi, newline        ; address of newline
    mov rdx, 1              ; number of bytes to write
    syscall

exit:
    ; Close file
    mov rax, 3              ; syscall number for sys_close
    mov rdi, [file_descriptor]  ; file descriptor
    syscall

    ; Exit program
    ret

; Convert binary line number to ASCII
convert_line_number_to_ascii:
    movzx rax, byte [line_number] ; Load line number into RAX (zero-extend to 64 bits)
    mov rcx, 10              ; Divisor for conversion
    mov rdi, ascii_buffer + 2 ; Point to the end of the ASCII buffer

convert_loop:
    xor rdx, rdx             ; Clear RDX for division
    div rcx                  ; RAX / 10, remainder in RDX
    add dl, '0'              ; Convert remainder to ASCII
    mov [rdi], dl            ; Store ASCII character
    dec rdi                  ; Move to the next position in the buffer
    cmp rax, 0               ; Check if quotient is zero
    jne convert_loop         ; If not, continue conversion

    ; Fill remaining positions with '0' if necessary
    cmp rdi, ascii_buffer
    jae done_conversion
    mov byte [rdi], '0'

done_conversion:
    ; Add a space after the line number
    mov byte [ascii_buffer + 3], ' '
    ret
