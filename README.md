# Basic x86 ASM Web Server

## Overview

This is a simple web server written in x86 Assembly only using Linux system calls. It adheres to the [x86 Calling Conventions](https://en.wikipedia.org/wiki/X86_calling_conventions#List_of_x86_calling_conventions) and is designed to be compliant with the HTTP/1.0 standard as defined in [RFC 1945](https://tools.ietf.org/html/rfc1945). I started this project to learn about the TCP/IP control structure and how it interacts with the HTTP protocol.

The web server supports **GET** and **POST** requests of varying lengths but is limited in that it can only handle requests up to a predefined size due to memory constraints and buffer management in assembly language. This project also provides insights into how process management works in Linux through the use of `fork()` and `execve()`, allowing the server to handle multiple connections simultaneously. Additionally, it covers file descriptor operations and low-level socket communication.

## Learning Outcomes

This project served as an excellent learning experience, offering a hands-on understanding of:

- TCP/IP networking and the HTTP protocol.
- Low-level system programming in Linux using assembly language.
- Process management and concurrency through system calls.
- File I/O operations and their interaction with system-level programming.


## Features

- **Supports GET and POST requests**: Handles basic HTTP requests (creating and reading from files with GET and POST requests, respectively) with limited error handling.
- **Parallel Processing**: Uses `fork()` to create child processes for handling multiple client connections concurrently.
- **File Handling**: Demonstrates file creation, reading, and writing using Linux syscalls.
- **Socket Communication**: Implements low-level networking through socket creation and binding.

## Requirements

- An x86_64 Linux environment.
- An assembler and linker (e.g., `as`, `ld`).
- Basic understanding of assembly language and Linux system calls.

## Getting Started

### Installation

1. Download `server.as` from this repository
2. Assemble the code into an object file using `as`:

```bash
as server.as -o server.o
```

3. Link the object file:
```bash
ld server.o -o server 
```

### Running the Server

1. Run the server with root privileges (port 80 requires elevated permissions):
   
```bash
sudo ./server
```

3. Send requests to the server!
   - **Example of GET request to retrieve the contents of the file index.html**
  
```bash
echo -e "GET /index.html HTTP/1.0\r\nHost: localhost\r\n\r\n" | nc localhost 80
```
     
   - **Example of POST request to create a file named text.txt and write "HelloWorld" to it:**
```bash
echo -e "POST /test HTTP/1.0\r\nHost: localhost\r\nContent-Length: 17\r\n\r\0test.txt\0HelloWorld" | nc localhost 80
```

## Code Explanation

### Main Components

- **Socket Creation**: The server creates a socket using the `socket` syscall.
- **Binding**: The socket is bound to port 80, allowing it to listen for incoming connections.
- **Listening for Connections**: The server listens for incoming connections using the `listen` syscall.
- **Accepting Connections**: When a client connects, the server accepts the connection and forks a new process to handle the request.
- **Handling Requests**:
  - **GET Requests**: The server opens the requested file, reads its contents, and sends them back to the client.
  - **POST Requests**: The server creates a new file based on the request data and sends an acknowledgment back to the client.

### Code Structure

- **.text Section**: Contains the main executable code, including the server logic.
- **.data Section**: Declares and initializes data used by the server, such as socket address structures and buffers.

## Limitations

- The server currently supports only basic HTTP features and does not handle multiple concurrent requests efficiently beyond the forking mechanism.
- It lacks comprehensive error handling and logging, making it unsuitable for production use.
- The request size is limited by the buffer size defined in the code.

## Contributing

Feel free to fork the repository and submit a pull request for improvements/bug fixes.
