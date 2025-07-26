;SnakeGame Project

[org 0x0100]
jmp start

; Constants 
SCREEN_WIDTH  equ 80
SCREEN_HEIGHT equ 25

; Variables
snake_char db 'O'
food_char  db '*'
score      db 0
foodX      db 30
foodY      db 10
snake_length     db 5
snake_direction          db 1

snake_head_x             db 40
snake_head_y             db 12

snake_body_x times 50 db 0
snake_body_y times 50 db 0

buffer times 2000 db ' '

; Program Start
start:
    mov ah, 0
    mov al, 3
    int 10h
    call clrscr
    call generate_food

main_loop:
    call update_snake_direction
    call update_snake_head
    call check_food_collision
    call draw_screen
    call delay
    jmp main_loop


; Input Handling
update_snake_direction:
    mov ah, 1
    int 16h
    jz end_update_snake_direction
    mov ah, 0h
    int 16h
    cmp al, 27
    jz near game_over_screen
    cmp ah, 48h
    jz up_key
    cmp ah, 50h
    jz down_key
    cmp ah, 4bh
    jz left_key
    cmp ah, 4dh
    jz right_key
    jmp update_snake_direction

;as up down requires y-axis
up_key:
    ; decrease one in y
    mov byte [snake_direction], 8
    jmp update_snake_direction

down_key:
    ;increase one in y
    mov byte [snake_direction], 4
    jmp update_snake_direction

; as right left requires x-axis 
left_key:
    ;decrease one in x
    mov byte [snake_direction], 2
    jmp update_snake_direction

right_key:
    ; increase one in x
    mov byte [snake_direction], 1
    jmp update_snake_direction

end_update_snake_direction:
    ret

; Update Snake Head 
update_snake_head:
    ; previous head position is saved
    mov al, [snake_head_x]
    mov [snake_body_x], al
    mov al, [snake_head_y]
    mov [snake_body_y], al

    ; shift body segments forward (from tail to head)
    mov cl, [snake_length]
    cmp cl, 1
    jle skip_shift_body

    mov si, cx
    dec si
shift_loop:
    mov al, [snake_body_x + si - 1]
    mov [snake_body_x + si], al
    mov al, [snake_body_y + si - 1]
    mov [snake_body_y + si], al
    dec si
    cmp si, 0
    jne shift_loop

skip_shift_body:

    ; Move head
    mov ah, [snake_direction]
    cmp ah, 8
    jz move_up
    cmp ah, 4
    jz move_down
    cmp ah, 2
    jz move_left
    cmp ah, 1
    jz move_right
;while moving forward we will check whether the snake approches to the wall if it so the game will over

move_up:
    dec byte [snake_head_y]
    jmp check_collisions

move_down:
    inc byte [snake_head_y]
    jmp check_collisions

move_left:
    dec byte [snake_head_x]
    jmp check_collisions

move_right:
    inc byte [snake_head_x]

check_collisions:
    ; Wall collision check
    mov al, [snake_head_x]
    cmp al, 0
    jl near game_over_screen  ; Left wall

    mov al, [snake_head_x]
    cmp al, SCREEN_WIDTH
    jge near game_over_screen ; Right wall

    mov al, [snake_head_y]
    cmp al, 0
    jl  near game_over_screen  ; Top wall

    mov al, [snake_head_y]
    cmp al, SCREEN_HEIGHT
    jge near game_over_screen ; Bottom wall

    ; Self-collision check
    call check_self_collision

    ret

; Check Self Collision
;if the location is same it will move to gameoverscreen otherwise it will increase si and then ret
check_self_collision:
    mov cx, [snake_length]  ; no of body segments to check
    dec cx                  ; removing head bcz we should want to check head again
    jz no_self_collision

    mov si, 1               ; start from second segment (index 1)
self_collision_loop:
    mov al, [snake_head_x]
    cmp al, [snake_body_x + si]
    jne next_segment
    mov al, [snake_head_y]
    cmp al, [snake_body_y + si]
    jne next_segment
    jmp game_over_screen      ; Collision with self

next_segment:
    inc si
    loop self_collision_loop

no_self_collision:
    ret

; Check for Food Collision 
check_food_collision:
    mov al, [snake_head_x]
    cmp al, [foodX]
    jne no_collision
    mov al, [snake_head_y]
    cmp al, [foodY]
    jne no_collision

    ; Clear old food from buffer
    mov al, [foodY]
    xor ah, ah
    mov bl, 80
    mul bl
    add ax, [foodX]
    mov di, buffer
    mov bx, ax
    mov byte [di + bx], ' '

    ; Food eaten!
    inc byte [score]
    inc byte [snake_length]
    cmp byte [snake_length], 50
    jge max_length
    jmp generate_new_food

max_length:
    mov byte [snake_length], 50

generate_new_food:
    call generate_food

no_collision:
    ret

; Draw Screen 
draw_screen:
    call clrscr

    ; draw Snake Head
    mov ah, 2
    mov bh, 0
    mov dh, [snake_head_y]
    mov dl, [snake_head_x]
    int 10h

    mov ah, 0Eh
    mov al, [snake_char]
    mov bh, 0
    mov bl, 15
    int 10h

    ; draw Snake Body
    mov si, 1
    mov cl, [snake_length]
    dec cl                  ; don't draw the head again
draw_body:
    mov ah, 2
    mov bh, 0
    mov dh, [snake_body_y + si]
    mov dl, [snake_body_x + si]
    int 10h

    mov ah, 0Eh
    mov al, [snake_char]
    mov bh, 0
    mov bl, 14
    int 10h

    inc si
    loop draw_body

    ; Draw Food
    mov ah, 2
    mov bh, 0
    mov dh, [foodY]
    mov dl, [foodX]
    int 10h

    mov ah, 0Eh
    mov al, [food_char]
    mov bh, 0
    mov bl, 12
    int 10h

; Draw Score
mov ah, 2
mov dh, 24
mov dl, 0
int 10h

mov ah, 0Eh
mov al, 'S'
int 10h
mov al, 'c'
int 10h
mov al, 'o'
int 10h
mov al, 'r'
int 10h
mov al, 'e'
int 10h
mov al, ':'
int 10h
mov al, ' '
int 10h

; Convert score to decimal digits
mov al, [score]
mov ah, 0

mov bl, 10
div bl          ; AX / 10 -> AL = quotient (tens), AH = remainder (units)

cmp al, 0
je print_units_only

; Print tens digit
add al, '0'
mov ah, 0Eh
mov al, al
int 10h

; Print units digit
mov al, ah
add al, '0'
mov ah, 0Eh
int 10h
jmp done_score_print

print_units_only:
; Only units digit to print
mov al, ah
add al, '0'
mov ah, 0Eh
int 10h

done_score_print:
ret


; Random Food Generation 
generate_food:
try_again:
    mov ah, 0
    int 1Ah
    mov ax, dx
    and ax, 0FFFh
    mul dx
    mov dx, ax
    mov ax, dx
    mov cx, 2000
    xor dx, dx
    div cx
    mov bx, dx
    mov di, buffer
    mov al, [di + bx]
    cmp al, ' '
    jnz try_again

    ; mark food in buffer
    mov byte [di + bx], '*'

    ; convert index to coordinates
    mov ax, bx
    mov bl, 80
    xor dx, dx
    div bl
    mov [foodY], al
    mov [foodX], ah
    ret

; Clear Screen 
clrscr:
    mov ax, 0600h
    mov bh, 07
    mov cx, 0
    mov dx, 184Fh
    int 10h
    ret

; Delay
delay:
    mov dx, 5          ; Outer loop count adjust to slow down
delay_outer_loop:
    mov cx, 0FFFFh     ; Inner loop count
delay_inner_loop:
    nop ;it is used to slow down the speed of snake
    loop delay_inner_loop
    dec dx
    jnz delay_outer_loop
    ret


; Game Over 
game_over_screen:
    call clrscr
    ; Move cursor to center and print "GAME OVER"
    mov ah, 2
    mov bh, 0
    mov dh, 12
    mov dl, 35
    int 10h

    mov ah, 0Eh
    mov al, 'G'
    int 10h
    mov al, 'A'
    int 10h
    mov al, 'M'
    int 10h
    mov al, 'E'
    int 10h
    mov al, ' '
    int 10h
    mov al, 'O'
    int 10h
    mov al, 'V'
    int 10h
    mov al, 'E'
    int 10h
    mov al, 'R'
    int 10h

    ; Move to next line and print "Score: "
    mov ah, 2
    mov bh, 0
    mov dh, 14
    mov dl, 30
    int 10h

    mov ah, 0Eh
    mov al, 'S'
    int 10h
    mov al, 'c'
    int 10h
    mov al, 'o'
    int 10h
    mov al, 'r'
    int 10h
    mov al, 'e'
    int 10h
    mov al, ':'
    int 10h
    mov al, ' '
    int 10h

    ; printing the scores in decimal that's why dividing by 10
    ; Print score
    mov al, [score]
    mov ah, 0
    mov bl, 10
    div bl            

    cmp al, 0
    je print_units_only_game_over

    ; Print tens digit
    add al, '0'
    mov ah, 0Eh
    int 10h

    ; Print units digit
    mov al, ah
    add al, '0'
    mov ah, 0Eh
    int 10h
    jmp done_score_print_game_over

print_units_only_game_over:
    mov al, ah
    add al, '0'
    mov ah, 0Eh
    int 10h

done_score_print_game_over:

    ; printing the msg "Press R to Restart or ESC to Exit"
    mov ah, 2
    mov bh, 0
    mov dh, 16
    mov dl, 25
    int 10h

    mov ah, 0Eh
    mov si, restart_msg
print_restart_msg:
    lodsb
    cmp al, 0
    je wait_for_choice
    int 10h
    jmp print_restart_msg

wait_for_choice:
    mov ah, 0
    int 16h
    cmp al, 'r'      ;it is handling upper and lower both cases 
    je restart_game
    cmp al, 'R'
    je restart_game
    cmp al, 27        ; ESC key
    je exit_game
    jmp wait_for_choice

restart_game:
    ; Reset game state
    mov byte [snake_head_x], 40
    mov byte [snake_head_y], 12
    mov byte [snake_length], 5
    mov byte [snake_direction], 1
    mov byte [score], 0

    ; Clear snake body X buffer
    mov cx, 50
    mov si, snake_body_x
    xor al, al
clear_body_x:
    mov [si], al
    inc si
    loop clear_body_x

    ; Clear snake body Y buffer
    mov cx, 50
    mov si, snake_body_y
clear_body_y:
    mov [si], al
    inc si
    loop clear_body_y

    call clrscr
    call generate_food
    jmp main_loop

exit_game:
    mov ax, 4C00h
    int 21h


restart_msg db 'Press R to Restart or ESC to Exit', 0
