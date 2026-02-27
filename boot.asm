org 0x7C00                                  ; BIOS loads boot sector at physical 0000:7C00
bits 16                                     ; Run in 16-bit real mode

start:                                      ; Boot entry point
    cli                                     ; Disable interrupts during segment/stack setup
    xor ax, ax                              ; AX = 0 for clean segment initialization
    mov ds, ax                              ; Data segment -> 0x0000
    mov es, ax                              ; Extra segment -> 0x0000
    mov ss, ax                              ; Stack segment -> 0x0000
    mov sp, 0x7C00                          ; Stack grows down from boot load address
    sti                                     ; Re-enable interrupts after setup
    cld                                     ; Ensure string ops increment SI/DI forward

    mov si, welcome_msg                     ; SI points to startup message
    call print_string                       ; Print greeting/instructions

main_loop:                                  ; Terminal REPL loop
    mov si, prompt                          ; SI points to prompt string
    call print_string                       ; Print prompt

    mov di, input_buffer                    ; DI points to start of command buffer
    xor cx, cx                              ; CX = current typed length

read_char:                                  ; Read one key and process it
    xor ah, ah                              ; INT 16h function 00h: blocking key read
    int 0x16                                ; Returns ASCII in AL (scan code in AH)
    cmp al, 0                               ; Ignore non-ASCII extended prefix byte
    je read_char                            ; Read next key if no ASCII byte yet

    cmp al, 0x0D                            ; Enter key?
    je process_input                        ; Submit command on Enter

    cmp al, 0x08                            ; Backspace key?
    je handle_backspace                     ; Handle erase/edit when backspace is pressed

    cmp cx, 31                              ; Keep one byte for NUL terminator (32-byte buffer)
    jae read_char                           ; Ignore extra typed chars when full

    stosb                                   ; Store typed ASCII byte at [DI], increment DI
    inc cx                                  ; Increment typed length
    call print_char                         ; Echo typed character to screen
    jmp read_char                           ; Continue input loop

handle_backspace:                           ; Remove one typed char if available
    cmp cx, 0                               ; Is buffer already empty?
    je read_char                            ; Nothing to delete
    dec di                                  ; Move write pointer back one position
    dec cx                                  ; Decrement typed length
    mov al, 0x08                            ; Backspace control char
    call print_char                         ; Move cursor left
    mov al, ' '                             ; Space to visually erase previous char
    call print_char                         ; Draw blank over old char
    mov al, 0x08                            ; Backspace again to restore cursor position
    call print_char                         ; Move cursor left once more
    jmp read_char                           ; Continue input loop

process_input:                              ; Finalize and execute command line
    mov al, 0                               ; NUL terminator byte
    stosb                                   ; Terminate command string at current DI
    mov si, newline                         ; SI points to CRLF string
    call print_string                       ; Move cursor to next line

    mov si, input_buffer                    ; SI points to typed command
    cmp byte [si], 0                        ; Empty command?
    je main_loop                            ; Re-prompt if user just pressed Enter

    mov di, cmd_help                        ; DI points to "help"
    call strcmp                             ; Compare input_buffer and cmd_help
    cmp al, 1                               ; strcmp returns 1 on equal
    je show_help                            ; Show help for matched command

    mov si, input_buffer                    ; Reset SI for next string compare
    mov di, cmd_clear                       ; DI points to "clear"
    call strcmp                             ; Compare input_buffer and cmd_clear
    cmp al, 1                               ; strcmp returns 1 on equal
    je clear_and_continue                   ; Clear screen for matched command

    mov si, unknown_msg                     ; SI points to unknown command message
    call print_string                       ; Print fallback message
    jmp main_loop                           ; Return to prompt

show_help:                                  ; Handle "help" command
    mov si, help_msg                        ; SI points to help message
    call print_string                       ; Print available commands
    jmp main_loop                           ; Return to prompt

clear_and_continue:                         ; Handle "clear" command
    call clear_screen                       ; Clear display and reset cursor
    jmp main_loop                           ; Return to prompt

print_char:                                 ; Print AL as teletype character
    mov ah, 0x0E                            ; BIOS video teletype function
    mov bh, 0                               ; Page number 0
    mov bl, 0x07                            ; Text attribute (light gray on black)
    int 0x10                                ; BIOS video interrupt
    ret                                     ; Return to caller

print_string:                               ; Print zero-terminated string from DS:SI
    lodsb                                   ; Load [SI] into AL, increment SI
    or al, al                               ; Set flags based on AL
    jz .done                                ; Stop when reaching NUL terminator
    call print_char                         ; Print current character
    jmp print_string                        ; Continue with next character
.done:                                      ; String print end
    ret                                     ; Return to caller

strcmp:                                     ; Compare zero-terminated strings SI and DI
.loop:                                      ; Per-character comparison loop
    mov al, [si]                            ; Load current char from first string
    mov ah, [di]                            ; Load current char from second string
    cmp al, ah                              ; Compare chars
    jne .not_equal                          ; Return mismatch if chars differ
    cmp al, 0                               ; End of both strings?
    je .equal                               ; Equal if both reached NUL together
    inc si                                  ; Advance first string pointer
    inc di                                  ; Advance second string pointer
    jmp .loop                               ; Continue comparing
.equal:                                     ; Equal strings path
    mov al, 1                               ; Return AL=1 for equal
    ret                                     ; Return to caller
.not_equal:                                 ; Not equal strings path
    xor al, al                              ; Return AL=0 for not equal
    ret                                     ; Return to caller

clear_screen:                               ; Clear text screen helper
    mov ax, 0x0003                          ; BIOS set video mode 03h (80x25 text, clears screen)
    int 0x10                                ; BIOS video interrupt
    ret                                     ; Return to caller

welcome_msg db "hello-os terminal", 13, 10, "type 'help' or 'clear'", 13, 10, 0 ; Welcome text + CRLF
prompt db "> ", 0                           ; Prompt text
newline db 13, 10, 0                        ; CRLF sequence
cmd_help db "help", 0                       ; Supported command: help
cmd_clear db "clear", 0                     ; Supported command: clear
help_msg db "commands: help, clear", 13, 10, 0 ; Help output text + CRLF
unknown_msg db "unknown command", 13, 10, 0 ; Unknown command output + CRLF
input_buffer times 32 db 0                  ; Command input buffer (31 chars + NUL)

times 510 - ($ - $$) db 0                   ; Pad boot sector to 510 bytes
dw 0xAA55                                   ; Boot signature
