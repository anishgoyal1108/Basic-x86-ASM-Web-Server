# System call numbers
SYS_EXIT        = 60          # Exit system call
SYS_SOCKET      = 41          # Create a socket
SYS_BIND        = 49          # Bind a socket to an address
SYS_LISTEN      = 50          # Listen for incoming connections
SYS_ACCEPT      = 43          # Accept a connection on a socket
SYS_READ        = 0           # Read from a file descriptor
SYS_WRITE       = 1           # Write to a file descriptor
SYS_OPEN        = 2           # Open a file
SYS_CLOSE       = 3           # Close a file descriptor

# Socket constants
AF_INET         = 2           # Address family for IPv4
SOCK_STREAM     = 1           # Type of socket for TCP
O_RDONLY        = 0           # Open file for reading only

# Server port number
PORT            = 0x5000      # Port 80 in big-endian format

.intel_syntax noprefix
.globl _start

.section .text

_start:
    # Create a socket
    mov rdi, AF_INET         # Address family
    mov rsi, SOCK_STREAM     # Socket type
    mov rdx, 0               # Protocol (IPPROTO_IP)
    mov rax, SYS_SOCKET      # Syscall number for socket
    syscall                  # Invoke syscall
    mov r9, rax              # Save socket file descriptor

    # Bind the socket to port 80
    mov rdi, r9              # Socket file descriptor
    mov rax, SYS_BIND        # Syscall number for bind
    lea rsi, [sockaddr_in]   # Pointer to sockaddr structure
    mov rdx, 0x10            # Size of sockaddr structure
    syscall                  # Invoke syscall

    # Listen for incoming connections
    mov rax, SYS_LISTEN      # Syscall number for listen
    mov rsi, 0               # Backlog (number of connections)
    mov rdx, 0x10            # Size of sockaddr structure
    syscall                  # Invoke syscall
    jmp main                 # Jump to main loop

main:
    # Accept a connection
    mov rax, SYS_ACCEPT      # Syscall number for accept
    mov rdi, r9              # Socket file descriptor
    mov rsi, 0               # NULL for sockaddr
    mov rdx, 0               # NULL for addrlen
    syscall                  # Invoke syscall
    mov r8, rax              # Save accepted file descriptor

    # Fork process to handle connection
    mov rax, 0x39            # Syscall number for fork
    syscall                  # Invoke syscall
    cmp rax, 0               # Check if in child process
    je child                 # Jump to child process handling

    # Parent Process
    mov rax, SYS_CLOSE       # Syscall number for close
    mov rdi, r8              # Accepted socket file descriptor
    syscall                  # Invoke syscall
    jmp main                 # Loop back to accept another connection

child:
    # Child Process
    # r8 contains accepted file descriptor, do not close it here.
    mov rdi, r8              # Set rdi to connection file descriptor for read/write
    mov rax, SYS_READ        # Syscall number for read
    lea rsi, [streamBuffer]   # Prepare buffer for reading
    mov rdx, 0x200           # Number of bytes to read
    syscall                  # Invoke syscall

    # Check the first byte of the stream buffer for a specific condition
    cmp byte ptr [streamBuffer], 0x47 # Compare first byte with 0x47
    je get                   # If equal, jump to 'get'

    # File creation process
    mov r10, rax             # Save number of bytes read
    mov rax, SYS_OPEN        # Syscall number for open
    mov BYTE PTR [streamBuffer + 21], 0x0 # Null terminate string
    lea rdi, [streamBuffer + 5] # Pointer to the filename in buffer
    mov rsi, 1 | 64          # Flags for creating the file
    mov rdx, 0777            # File mode (permissions)
    syscall                  # Invoke syscall to create file

    mov rdi, rax             # Set rdi to the new file descriptor
    mov rax, SYS_WRITE       # Syscall number for write
    call loop                # Process loop

    # Write remaining bytes to file
    lea rsi, [streamBuffer + rbx] # Adjust buffer pointer
    sub r10, rbx             # Calculate remaining bytes to write
    mov rdx, r10             # Number of byte to write
    syscall                  # Write to file

    # Close file descriptor
    mov r9, rax              # Save result of write
    mov rax, SYS_CLOSE       # Syscall number for close
    syscall                  # Close file descriptor

    # Write ACK packet back to the connection
    mov rdi, r8              # Set rdi to connection file descriptor
    mov rax, SYS_WRITE       # Syscall number for write
    lea rsi, [out]           # Pointer to ACK message
    mov rdx, 0x13            # Length of the ACK message
    syscall                  # Invoke syscall to write ACK

    # Exit the process
    mov rax, SYS_EXIT        # Syscall number for exit
    mov rdi, 0               # Exit code
    syscall                  # Invoke syscall to exit

get:
    # Open the specified file
    mov rax, SYS_OPEN        # Syscall number for open
    mov BYTE PTR [streamBuffer + 20], 0x0 # Null terminate filename
    lea rdi, [streamBuffer + 4] # Pointer to the filename in buffer
    mov rsi, 0               # Flags (0 for read-only)
    mov rdx, 0               # Mode (not used for open)
    syscall                  # Invoke syscall to open file

    mov rdi, rax             # Set rdi to file descriptor
    mov rax, SYS_READ        # Syscall number for read
    lea rsi, [fileBuffer]    # Pointer to buffer for file contents
    mov rdx, 0x200           # Number of bytes to read
    syscall                  # Invoke syscall to read from file

    mov r9, rax              # Save bytes read
    mov rax, SYS_CLOSE       # Syscall number for close
    syscall                  # Close file descriptor

    # Write ACK packet back to the connection
    mov rdi, r8              # Set rdi to connection file descriptor
    mov rax, SYS_WRITE       # Syscall number for write
    lea rsi, [out]           # Pointer to ACK message
    mov rdx, 0x13            # Length of the ACK message
    syscall                  # Invoke syscall to write ACK

    # Write the contents of the file to the connection
    mov rax, SYS_WRITE       # Syscall number for write
    lea rsi, [fileBuffer]    # Pointer to the file contents
    mov rdx, r9              # Number of bytes read
    syscall                  # Invoke syscall to write file contents

    # Exit the process
    mov rax, SYS_EXIT        # Syscall number for exit
    mov rdi, 0               # Exit code
    syscall                  # Invoke syscall to exit process

loop:
    # Loop through buffer to find a specific pattern
    cmp dword ptr [streamBuffer + rbx], 0xa0d0a0d # Compare to pattern
    je found_it              # Jump to found_it if pattern matches
    inc rbx                  # Increment buffer index
    jmp loop                 # Repeat the loop

found_it:
    # Adjust buffer index after finding the pattern
    add rbx, 0x4             # Move index past the found pattern
    ret                       # Return from loop

.section .data

sockaddr_in:
    .word AF_INET            # Address family (IPv4)
    .word PORT               # Port 80 (big-endian)
    .word 0                  # IP address (INADDR_ANY)
    .word 0                  # IP address (INADDR_ANY)
    .byte 0                  # Padding byte

streamBuffer:
    .space 0x200             # Buffer for incoming data

fileBuffer:
    .space 0x200             # Buffer for file contents

outputBuffer:
    .space 0x200             # Buffer for output data

out:
    .string "HTTP/1.0 200 OK\r\n\r\n" # HTTP response header
