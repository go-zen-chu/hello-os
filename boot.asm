org 0x7C00
bits 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld

    mov si, welcome_msg
    call print_string

main_loop:
    mov si, prompt
    call print_string

    mov di, input_buffer
    xor cx, cx

read_char:
    xor ah, ah
    int 0x16
    cmp al, 0
    je read_char

    cmp al, 0x0D
    je process_input

    cmp al, 0x08
    je handle_backspace

    cmp cx, 31
    jae read_char

    stosb
    inc cx
    call print_char
    jmp read_char

handle_backspace:
    cmp cx, 0
    je read_char
    dec di
    dec cx
    mov al, 0x08
    call print_char
    mov al, ' '
    call print_char
    mov al, 0x08
    call print_char
    jmp read_char

process_input:
    mov al, 0
    stosb
    mov si, newline
    call print_string

    mov si, input_buffer
    cmp byte [si], 0
    je main_loop

    mov si, input_buffer
    mov di, cmd_help
    call strcmp
    cmp al, 1
    je show_help

    mov si, input_buffer
    mov di, cmd_clear
    call strcmp
    cmp al, 1
    je clear_and_continue

    mov si, unknown_msg
    call print_string
    jmp main_loop

show_help:
    mov si, help_msg
    call print_string
    jmp main_loop

clear_and_continue:
    call clear_screen
    jmp main_loop

print_char:
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x07
    int 0x10
    ret

print_string:
    lodsb
    or al, al
    jz .done
    call print_char
    jmp print_string
.done:
    ret

strcmp:
.loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .not_equal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .loop
.equal:
    mov al, 1
    ret
.not_equal:
    xor al, al
    ret

clear_screen:
    mov ax, 0x0003
    int 0x10
    ret

welcome_msg db "hello-os terminal", 13, 10, "type 'help' or 'clear'", 13, 10, 0
prompt db "> ", 0
newline db 13, 10, 0
cmd_help db "help", 0
cmd_clear db "clear", 0
help_msg db "commands: help, clear", 13, 10, 0
unknown_msg db "unknown command", 13, 10, 0
input_buffer times 32 db 0

times 510 - ($ - $$) db 0
dw 0xAA55
