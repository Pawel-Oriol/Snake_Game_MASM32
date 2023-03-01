.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dWExitCode: DWORD
clock PROTO C: DWORD

include \masm32\include\masm32rt.inc
include \masm32\macros\macros.asm   
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\msvcrt.lib

.data
	; define viariables here
	game_state BYTE  0
	end_text BYTE "GAME OVER. New game? Press y (yes) or n (no)",0
	score_text BYTE "Score: ",0
	score_val_string BYTE 10 DUP (0)
	start_time SDWORD 0
	curr_time SDWORD 0
	console_handle DWORD 0

	
	score SDWORD 153
	;snake data
	snake_pos_x SDWORD 5
	snake_pos_y SDWORD 5
	move_dir DWORD 1  ; directions: 0 -up, 1 - left, 2 - down, 3 - right
	snake_body SDWORD 4,5,3,5,2,5, 400 DUP(-1) ;enough space for a snake covering all the grid
	snake_length DWORD 3

	;food 
	food_pos_x SDWORD 5
	food_pos_y SDWORD 0
.code


;;;;reset game;;;;
restart_game PROC
push ebp
mov ebp, esp
mov game_state, 0
mov score, 0
mov food_pos_x, 5
mov food_pos_y, 0
mov move_dir, 1
mov snake_length,  3
mov snake_pos_x,5
mov snake_pos_y,5

mov ecx,3
my_loop:
push ecx
xor edx, edx
mov eax, ecx
sub eax, 1
push eax
mov edx, 2*4
mul edx
mov edi, eax

pop eax
mov ebx, 4
sub ebx, eax 
mov snake_body[edi], ebx
add edi,4
mov snake_body[edi], 5
pop ecx
loop my_loop

call clock
mov start_time, eax

push ' '
push 100
push 100
push 0
push 0
call DrawRectangleFilled
pop ebx
pop ebx
pop ebx
pop ebx
pop ebx

mov esp, ebp
pop ebp
restart_game ENDP


;could have used printf, but decided to do it 
;from scratch as an exercise 
convert_int_to_string PROC
push ebp
mov ebp, esp
mov eax, score
mov ecx, 0
my_loop:
xor     edx,edx
mov ebx, 10
div ebx
add edx, '0' ;add '0' to get an ASCII code for this digit
mov score_val_string[ecx], dl
add ecx, 1
cmp eax, 0	
jne my_loop
push ecx
;need to reverse the digits' order
xor edx, edx
sub ecx, 1
mov eax, ecx
mov ebx, 2
div ebx
mov ebx, 0
;in place list reversal
;ebx - left side; ecx - right side
my_loop2:
	mov dl, score_val_string[ecx]
	mov dh, score_val_string[ebx]
	mov score_val_string[ecx], dh
	mov score_val_string[ebx],dl
	add ebx, 1
	sub ecx, 1
	cmp ebx, eax
	jbe my_loop2

pop eax
sub eax, 1
mov esp, ebp
pop ebp
ret
convert_int_to_string ENDP

;;;;
;args: x, y - coordinates on the console screen
print_score PROC
push ebp
mov ebp, esp
push SDWORD PTR -11
call GetStdHandle
pop ebx
mov console_handle, eax
;push WORD PTR [ebp +12]
;push WORD PTR [ebp +8]
;push DWORD PTR console_handle
mov eax, [ebp+12]
shl eax, 16
mov ax, [ebp+8]
invoke SetConsoleCursorPosition,console_handle, eax



invoke crt_printf, offset score_text
call convert_int_to_string
mov ecx, 0
myLoop:
	push ecx
	push eax
	mov bl, score_val_string[ecx]
	invoke crt_putchar,bl
	pop eax
	pop ecx
	add ecx,1
	cmp ecx, eax
	jle myLoop

mov esp, ebp
pop ebp
ret
print_score ENDP

;;;;
;x, y
print_end_game PROC
push ebp
mov ebp, esp
push SDWORD PTR -11
call GetStdHandle
pop ebx
mov console_handle, eax
;push WORD PTR [ebp +12]
;push WORD PTR [ebp +8]
;push DWORD PTR console_handle
mov eax, [ebp+12]
shl eax, 16
mov ax, [ebp+8]
invoke SetConsoleCursorPosition,console_handle, eax
invoke crt_printf, offset end_text
mov esp, ebp
pop ebp
ret
print_end_game ENDP

;;;;max_x, max_y;;;;
Check_Game_Over PROC
push ebp
mov ebp, esp

;test wall x
mov eax, -1
cmp eax, snake_pos_x
je ret_game_over

mov eax, [ebp+8]
cmp eax, snake_pos_x
je ret_game_over

;test wall y
mov eax, -1
cmp eax, snake_pos_y
je ret_game_over

mov eax, [ebp+12]
cmp eax, snake_pos_y
je ret_game_over

push snake_pos_y
push snake_pos_x
call Check_Collision_With_Snake_Body
pop ebx
pop ebx
cmp eax, 1
je ret_game_over
jmp ret_not_game_over

ret_game_over:
mov game_state, 1 
mov eax, 1
mov esp, ebp
pop ebp
ret

ret_not_game_over:
mov eax,0
mov esp, ebp
pop ebp
ret
Check_Game_Over ENDP

Check_Collision_With_Snake_Body PROC
push ebp
mov ebp, esp

mov ecx, snake_length
my_loop:
	push ecx
	mov eax, 4*2 
	mov edx, ecx
	sub edx, 1 ;o jeden mniej
	mul edx
	mov esi, eax
	mov eax, snake_body[esi]
	cmp eax, [ebp+8]
	je check_y
	jmp end_loop
	check_y:
	mov eax, snake_body[esi+4]
	cmp eax, [ebp+12]
	je return_collision
	jmp end_loop

	return_collision:
	mov eax, 1
	pop ecx
	mov esp, ebp
	pop ebp
	ret

	end_loop:
	pop ecx
	loop my_loop

mov eax, 0
mov esp, ebp
pop ebp
ret
Check_Collision_With_Snake_Body ENDP

;x, y
Check_Collision_With_Snake PROC
push ebp
mov ebp, esp


mov eax, snake_pos_x
cmp eax, [ebp+8]
je check_y
jmp body_collision_check

check_y:
mov eax, snake_pos_y
cmp eax, [ebp+12]
je ret_collision

body_collision_check:
push [ebp+12]
push [ebp+8]
call Check_Collision_With_Snake_Body
pop ebx
pop ebx
cmp eax, 1
je ret_collision
jmp ret_no_collision

ret_collision:
mov eax, 1
mov esp, ebp
pop ebp
ret

ret_no_collision:
mov eax, 0
mov esp, ebp
pop ebp
Check_Collision_With_Snake ENDP
ret

Eat_Food PROC
mov eax, snake_pos_x
cmp eax, food_pos_x
je test_y
jmp end_eat

test_y:
mov eax, snake_pos_y
cmp eax, food_pos_y
je eaten
jmp end_eat
eaten:
mov eax, snake_length
add eax, 1
mov snake_length, eax

sub eax, 1
mov edx, 2*4
mul edx
mov esi, eax
sub esi,8
mov ebx, snake_body[esi]
mov snake_body[eax], ebx
add eax, 4
add esi, 4
mov ebx, snake_body[esi]
mov snake_body[eax], ebx

mov eax, score
add eax, 1
mov score, eax
push DWORD PTR 10-2
push DWORD PTR 20-2
call Random_Food
pop ebx
pop ebx
end_eat:
ret
Eat_Food ENDP

;args: x_range, y range to compute the new position of food
Random_Food PROC
push ebp
mov ebp, esp
new_random_food:
call clock
div DWORD PTR [ebp+8]
mov food_pos_x, edx
call clock
div DWORD PTR [ebp+12]
mov food_pos_y, edx
push DWORD PTR food_pos_y
push DWORD PTR food_pos_x
call Check_Collision_With_Snake
pop ebx
pop ebx
cmp eax, 1
je new_random_food
mov esp, ebp
pop ebp
ret
Random_Food ENDP

;non blocking check of key pressed without echo
Key_Pressed_No_Block PROC
	call crt__kbhit
	cmp eax, 1
	je key_pressed
	jmp end_proc
	key_pressed:
	call crt__getch
	end_proc:
	ret
Key_Pressed_No_Block ENDP

;method for turning snake right or left ('a' and 'd' keys)
Process_Input PROC
	invoke crt__kbhit
	cmp eax, 1
	je key_pressed
	jmp end_proc
	key_pressed:
	invoke crt__getch
	cmp eax, 'a'
		je turn_left
	cmp eax, 'd'
		je turn_right
	jmp end_proc
	turn_left:
		mov eax, move_dir
		sub eax, 1
		cmp eax, 0
		jl fix_min
		jmp save_dir
		fix_min:
		mov eax, 3
		jmp save_dir
	turn_right:
		mov eax, move_dir
		add eax, 1
		cmp eax, 3
		jg fix_max
		jmp save_dir
		fix_max:
		mov eax, 0
		jmp save_dir
	save_dir:
		mov move_dir, eax
	end_proc:
	ret
Process_Input ENDP

Move_Snake_Head PROC
cmp move_dir,0
je move_up

cmp move_dir,1
je move_right

cmp move_dir,2
je move_down

cmp move_dir,3
je move_left

move_up:
	mov eax, snake_pos_y
	sub eax, 1
	mov snake_pos_y,eax
	jmp end_move

move_right:
	mov eax, snake_pos_x
	add eax, 1
	mov snake_pos_x,eax
	jmp end_move

move_down :
	mov eax, snake_pos_y
	add eax, 1
	mov snake_pos_y,eax
	jmp end_move

move_left:
	mov eax, snake_pos_x
	sub eax, 1
	mov snake_pos_x,eax
	jmp end_move
end_move:
	ret

Move_Snake_Head ENDP

Move_Snake_Body PROC
mov ecx, snake_length
sub ecx, 1 ; one less, since the neck needs to receive old heads coords


loop_snake_body:
	push ecx
	mov ebx, ecx		;index of destination segment	
	mov edx, ebx
	sub edx, 1			;index of source segment
	mov eax, ebx
	mov ecx, 2*4	;two coordinates, 4 bytes each = segment size
	push edx
	mul ecx
	pop edx
	mov edi, eax
	mov eax, edx
	push edx
	mul ecx
	pop edx
	mov esi, eax
	mov eax, snake_body[esi]  ;each segment gets the position of the one before him
	mov snake_body[edi], eax
	add esi, 4
	add edi, 4
	mov eax, snake_body[esi]
	mov snake_body[edi], eax
	pop ecx
	loop loop_snake_body

;neck receives heads coords
mov eax, snake_pos_x
mov snake_body[0], eax
mov eax, snake_pos_y
mov snake_body[4], eax

ret
Move_Snake_Body ENDP

;args: offset x, offset y - you can change the place where to display game screen
Draw_Snake_Head PROC
push ebp
mov ebp, esp
push '0'
;offsets
mov eax, snake_pos_y
add eax, [ebp+12]
push eax
mov eax, snake_pos_x
add eax, [ebp+8]
push eax

call Put_Pixel
pop ebx
pop ebx
pop ebx
mov esp, ebp
pop ebp
ret
Draw_Snake_Head ENDP

;args: offset x, offset y - you can change the place where to display game screen
Draw_Snake_Body PROC
push ebp
mov ebp, esp
mov ecx, snake_length

draw_loop:
	push ecx
	mov eax, ecx
	sub eax, 1
	mov ebx, 2*4 ;dwie pozycje i 4 bajty na integer
	mul ebx
	push '0'
	add eax,4
	mov edx, snake_body[eax]
	add edx, [ebp+12]
	push edx
	sub eax,4
	mov edx, snake_body[eax]
	add edx, [ebp+8]
	push edx
	call Put_Pixel
	pop ebx
	pop ebx
	pop ebx
	pop ecx
	loop draw_loop
mov esp, ebp
pop ebp
ret
Draw_Snake_Body ENDP


;args: offset x, offset y - you can change the place where to display game screen
Draw_Food PROC
push ebp
mov ebp, esp
push 'X'
;offsets
mov eax, food_pos_y
add eax, [ebp+12]
push eax
mov eax, food_pos_x
add eax, [ebp+8]
push eax

call Put_Pixel
pop ebx
pop ebx
pop ebx
mov esp, ebp
pop ebp
ret
Draw_Food ENDP


;args: offset x, offset y - you can change the place where to display game screen
draw_snake_macro MACRO offset_x, offset_y
	
	push offset_y
	push offset_x
	call Draw_Food
	call Draw_Snake_Head
	call Draw_Snake_Body
	pop ebx
	pop ebx
	
ENDM

;args: x,y,val
Put_Pixel PROC
push ebp
mov ebp, esp
push SDWORD PTR -11
push SDWORD PTR -11
call GetStdHandle
pop ebx
mov console_handle, eax
mov eax, [ebp+12]
shl eax, 16
mov ax, [ebp+8]
invoke SetConsoleCursorPosition,console_handle, eax
invoke crt_putchar, BYTE PTR  [ebp+16]
mov esp, ebp
pop ebp
ret

Put_Pixel ENDP



;args:posX, posY, w, h, val
DrawRectangleFilled PROC
	push ebp
	mov ebp, esp
	
	mov ecx, [ebp+20] ;h

	loop_y:
		push ecx
		mov ecx, [ebp+16] ; w
		loop_x:
			push ecx

			push [ebp+24]; val
			mov eax, [esp+8] ;obecny index y
			add eax, [ebp+12] ; dodaj polozoenie y
			sub eax, 1 ; musimy odjac jeden, zeby bylo od zera
			push eax 

			mov eax, ecx
			add eax, [ebp+8] ; dodaj polozoenie x
			sub eax, 1; musimy odjac jeden, zeby bylo od zera
			push eax
			call Put_Pixel
			pop ebx
			pop ebx
			pop ebx

			pop ecx
			loop loop_x
		pop ecx
		loop loop_y

	mov esp,ebp
	pop ebp
	ret

DrawRectangleFilled ENDP

draw_rectangle_macro MACRO pos_x, pos_y, w, h, val
	
	push val
	push h
	push w
	push pos_y
	push pos_x
	call DrawRectangleFilled
	pop ebx
	pop ebx
	pop ebx
	pop ebx
	pop ebx
ENDM

;args: posX, posY, w, h
Draw_Border PROC
push ebp
mov ebp, esp

push 'O'
push [ebp+20]
push [ebp+16]
push [ebp+12]
push [ebp+8]
call DrawRectangleFilled
pop ebx
pop ebx
pop ebx
pop ebx
pop ebx

push ' '
mov eax,[ebp+20]
sub eax,2
push eax
mov eax, [ebp+16]
sub eax,2
push eax
mov eax, [ebp+12]
add eax,1
push eax
mov eax, [ebp+8]
add eax,1
push eax
call DrawRectangleFilled

mov esp, ebp
pop ebp
ret
Draw_Border ENDP

draw_border_macro MACRO pos_x, pos_y, w, h
	
	push h
	push w
	push pos_y
	push pos_x
	call Draw_Border
	pop ebx
	pop ebx
	pop ebx
	pop ebx
ENDM


main PROC
	start_game:
	call restart_game
	draw_border_macro 1,2,20,10
	mov ecx, 10
	main_loop:
		mov al, game_state
		cmp al, 1
		je game_over
		
		game_mode:
			push ecx
			call clock
			mov curr_time, eax
			sub eax, start_time
			;update game every 500 ticks (about half a second on windows)
			cmp eax, 500
			jg update_game
			jmp dont_update_game
			update_game:
				call Process_Input
				;clear the grid except for border
				draw_rectangle_macro 2,3,18,8,' '
				call Move_Snake_Body
				call Move_Snake_Head
				push DWORD PTR 10-2
				push DWORD PTR 20-2
				call Eat_Food
				call Check_Game_Over
				pop ebx
				pop ebx
				cmp eax, 1
				je game_over
				draw_snake_macro 2,3
				push 5
				push 25
				call print_score
				pop ebx
				pop ebx
				call clock
				mov start_time, eax
			dont_update_game:
				pop ecx
				jmp main_loop
		game_over:
		push 15
		push 25
		call print_end_game
		pop ebx
		pop ebx
		call Key_Pressed_No_Block
		cmp eax, 'y'
			je start_game
		cmp eax, 'n'
			je exit_game
		jmp main_loop
	exit_game:
	INVOKE ExitProcess, 0
main ENDP
END main