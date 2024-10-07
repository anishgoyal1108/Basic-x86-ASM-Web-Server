.intel_syntax noprefix
.globl _start

.section .text

_start:
    mov rdi, 0x2                     # AF_INET (IPv4)
    mov rsi, 0x1                     # SOCK_STREAM
    xor rdx, rdx                     # Protocol 0 (IP)
    mov rax, 0x29                    # syscall: socket()
    syscall
    mov r9, rax                      # Save socket file descriptor in r9
    
    mov rdi, r9
    lea rsi, [sockaddr_in]            # Address structure for binding
    mov rdx, 0x10                    # Length of sockaddr_in
    mov rax, 0x31                    # syscall: bind()
    syscall

    mov rdi, r9
    xor rsi, rsi                     # Backlog (0)
    mov rax, 0x32                    # syscall: listen()
    syscall

main:
    mov rdi, r9
    xor rsi, rsi
    xor rdx, rdx
    mov rax, 0x2B                    # syscall: accept()
    syscall
    mov r8, rax                      # Store client socket in r8

    mov rax, 0x39                    # syscall: fork()
    syscall
    test rax, rax                    # Check if child
    jnz parent                       # If not child, jump to parent

child:
    mov rdi, r9                      # Close server socket in child
    mov rax, 0x3                     # syscall: close()
    syscall

    mov rdi, r8                      # Set up read on client socket
    lea rsi, [streamBuffer]           # Buffer to read into
    mov rdx, 0x200                   # Max read size
    xor rax, rax                     # syscall: read()
    syscall

    cmp byte ptr [streamBuffer], 0x47 # Check if input is GET request (ASCII 'G')
    je get                           # If GET, jump to get handling

    mov r10, rax                     # Save read count

    # Handle POST (create file and write data)
    mov BYTE PTR [streamBuffer + 21], 0x0
    lea rdi, [streamBuffer + 5]       # Filename in buffer
    mov rsi, 1 | 64                  # Flags: O_WRONLY | O_CREAT
    mov rdx, 0777                    # Permissions: 0777
    mov rax, 0x2                     # syscall: open()
    syscall

    mov rdi, rax                     # Use returned file descriptor for writing
    lea rsi, [streamBuffer+rbx]
    sub r10, rbx                     # Adjust size based on file content
    mov rdx, r10
    mov rax, 0x1                     # syscall: write()
    syscall

    mov rax, 0x3                     # syscall: close()
    syscall

    mov rdi, r8                      # Send HTTP response
    lea rsi, [out]
    mov rdx, 0x13
    mov rax, 0x1                     # syscall: write()
    syscall

    mov rax, 0x3C                    # syscall: exit()
    xor rdi, rdi                     # exit(0)
    syscall

get:
    mov BYTE PTR [streamBuffer + 20], 0x0
    lea rdi, [streamBuffer + 4]       # Filename to open
    xor rsi, rsi                     # Flags: O_RDONLY
    xor rdx, rdx                     # Mode (unused)
    mov rax, 0x2                     # syscall: open()
    syscall

    mov rdi, rax                     # Use file descriptor from open()
    lea rsi, [fileBuffer]             # Buffer to read into
    mov rdx, 0x200                   # Max read size
    xor rax, rax                     # syscall: read()
    syscall

    mov r9, rax                      # Store read count
    mov rax, 0x3                     # syscall: close()
    syscall

    mov rdi, r8                      # Send HTTP response
    lea rsi, [out]
    mov rdx, 0x13
    mov rax, 0x1                     # syscall: write()
    syscall

    mov rdi, r8                      # Send file contents
    lea rsi, [fileBuffer]
    mov rdx, r9                      # Number of bytes to send
    syscall                          # syscall: write()

    mov rax, 0x3C                    # syscall: exit()
    xor rdi, rdi                     # exit(0)
    syscall

parent:
    mov rdi, r8                      # Close client socket in parent
    mov rax, 0x3                     # syscall: close()
    syscall
    jmp main                         # Loop back to main for new connections

loop:
    cmp dword ptr [streamBuffer+rbx], 0xa0d0a0d # Search for newline (GET end marker)
    je found_it
    inc rbx
    jmp loop

found_it:
    add rbx, 0x4                     # Move past marker
    ret

.section .data

sockaddr_in:
    .word 0x2                        # AF_INET
    .word 0x5000                     # Port 80 (Big Endian)
    .word 0x0
    .word 0x0
    .byte 0x0

streamBuffer:
    .space 0x200

fileBuffer:
    .space 0x200

out:
    .string "HTTP/1.0 200 OK\r\n\r\n"
