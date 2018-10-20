	;; KB74293
section .data
	;; General Program Variables
	debug		db "Do you want to enable debug information?", 0xA
	debug_l		equ $ - debug
	finalb          db "Final board: ", 0xA
	finalb_l        equ $ - finalb
	currb           db "Current board: ", 0xA
	currb_l         equ $ - currb
	msg             db "Choose board size (3, 4, 5): ", 0xA
	msg_l           equ $ - msg
	inv		db "That location is out of range or already taken.", 0xA
	inv_l           equ $ - inv
	eol             db 0xA
	eol_l           equ $ - eol
	winx            db "Player X wins!", 0xA
	winx_l          equ $ - winx
	wino            db "Player O wins!", 0xA
	wino_l          equ $ - wino
	tie             db "It's a draw (tie)!", 0xA
	tie_l           equ $ - tie
	nvalid          db "Choice is not valid! Choose again", 0xA
	nvalid_l        equ $ - nvalid
	xwin            db "Player X wins!", 0xA
	xwin_l          equ $ - xwin
	owin            db "Player O wins!", 0xA
	owin_l          equ $ - owin
	bombx           db "Player X place a bomb:", 0xA
	bombx_l         equ $ - bombx
	bombo           db "Player O place a bomb:", 0xA
	bombo_l         equ $ - bombo
	;; 3x3 Board Variables
	loc3            db "         ", 0xA
	loc3_l          equ $ - loc3
	px3             db "Player X, choose your location (0-8): ", 0xA
	px3_l           equ $ - px3
	po3             db "Player O, choose your location (0-8): ", 0xA
	po3_l           equ $ - po3
	brd3            db " | | ", 0xA
	brd3_l          equ $ - brd3
	brd3ln          db "-----", 0xA
	brd3ln_l        equ $ - brd3ln
	;; 4x4 Board Variables
	loc4            db "                ", 0xA
	loc4_l          equ $ - loc4
	px4             db "Player X, choose your location (0-15): ", 0xA
	px4_l           equ $ - px4
	po4             db "Player O, choose your location (0-15): ", 0xA
	po4_l           equ $ - po4
	brd4            db " | | | ", 0xA
	brd4_l          equ $ - brd4
	brd4ln          db "-------", 0xA
	brd4ln_l        equ $ - brd4ln
	;; 5x5 Board Variables
	loc5            db "                         ", 0xA
	loc5_l          equ $ - loc5
	px5             db "Player X, choose your location (0-24): ", 0xA
	px5_l           equ $ - px5
	po5             db "Player O, choose your location (0-24): ", 0xA
	po5_l           equ $ - po5
	brd5            db " | | | | ", 0xA
	brd5_l          equ $ - brd5
	brd5ln          db "---------", 0xA
	brd5ln_l        equ $ - brd5ln
	
	
section .bss
	;; More General Purpose Variables
	usr             resb 1
	bsize           resb 1
	iter            resb 1
	rowiter         resb 1
	msgpos          resb 1
	turns           resb 1
	state           resb 1
	player          resb 1
	pos1            resb 1
	pos2            resb 1
	pos3            resb 1
	pos4            resb 1
	pos5            resb 1
	itermat         resb 1
	xbomb           resb 1
	obomb           resb 1
	explody		resb 1
	
section .text
global _start

	;; /////////////////////////////////
	;; General Purpose Subroutines
	;; /////////////////////////////////
print_int:
        mov     eax, 4
	mov     ebx, 1
	int     0x80
ret

read_int:
	mov     eax, 3
	xor     ebx, ebx
	int 	0x80
ret

abort:
	mov	eax, 1
	xor	ebx, ebx
	int 	0x80
ret

get_size:
	mov     ecx, msg 		;Print choose board size
	mov     edx, msg_l
	call    print_int
	
	mov     ecx, bsize 		;Get user board size choice
	mov     edx, 2
	call    read_int

	;;; Check if the entered size is valid
	movzx   eax, byte[bsize]
	sub     al, '0'
	cmp     al, 3			;Abort if less than 3
	jl      abort
	cmp     al, 5			;Abort if greater than 5
	jg      abort
ret

convert_int:
	cmp     byte[usr+1], 0xA 	;Check whether user input is one digit/two digit using position of 0xA.
	je      one_digit
	cmp     byte[usr+2], 0xA
	je      two_digit
one_digit:
	movzx   eax, byte[usr]		;If one digit, just convert as normal.
	sub     al, '0'
	mov     [usr], eax
	jmp     convert_out
two_digit:
	movzx   eax, byte[usr]		;If two digit, separate the two ASCII and convert separately.
	sub     al, '0'
	movzx   ebx, byte[usr+1]
	sub     bl, '0'
	imul    eax, eax, 10		;Convert tens place (multiply by 10).
	add     eax, ebx		;Add ones place and tens place for final number.
	mov     [usr], eax
	jmp     convert_out
convert_out:
ret
	
	
	;; ////////////////////////////
	;; 3x3 Board Subroutines
	;; ////////////////////////////
play3:
	mov	byte[explody], 0
	call    place_bomb3x
	call    place_bomb3o
start3:	
	mov     ecx, px3
	mov     edx, px3_l
	call    print_int
	
	mov     byte[player], 'X' 	;Player X's turn
	call    player3			;Get Player X's choice
	call    check_bomb3		;Check if the choice exploded O's bomb
	call    find_match3		;Check if the choice has completed a match
	
	inc     byte[turns]		
	cmp     byte[turns], 5		;Game will end in tie if player X has had 5 turns.
	je      tie3
	
	mov     ecx, po3
	mov     edx, po3_l
	call    print_int
	
	mov     byte[player], 'O' 	;Player O's turn
	call    player3			;Get Player O's choice
	call    check_bomb3		;Check if the choice exploded X's bomb
	call    find_match3		;Check if the choice has completed a match
	
	jmp     start3

	
check_bomb3:
	;;;  Execute based on current player
	cmp     byte[player], 'X'
	je      currx3
	cmp     byte[player], 'O'
	je      curro3
currx3:
	;;;  Know that current player is X	
	;;;  Need to know if the position chosen in usr is same as obomb
	;;;  If true jump to win3
	;;;  If false ret
	movzx   eax, byte[usr]
	sub     al, '0'
	movzx   ebx, byte[obomb]
	sub     bl, '0'
	cmp     al, bl
	je      explodex3
	jmp     no_explode3
curro3:
	;;;  Know that the current player is O
	;;;  Need to know if the position chosen in usr is same as xbomb
	;;;  If true jump to win3
	;;;  If false ret
	movzx   eax, byte[usr]
	sub     al, '0'
	movzx   ebx, byte[xbomb]
	sub     bl, '0'
	cmp     al, bl
	je      explodeo3
	jmp     no_explode3
explodex3:
	;;;  O's bomb exploded so O wins
	mov	byte[explody], 1
	mov     byte[player], 'O'		;Change winner to O
	movzx   eax, byte[xbomb]
	mov     bl, '1'				;Put a 1 where X's bomb was
	mov     [loc3+eax], bl 
	movzx   eax, byte[usr]
	mov     bl, '@'
	mov     [loc3+eax], bl			;Put explosion symbol on the last position chosen 
	jmp     win3
explodeo3:
	;;;  X's bomb exploded so X wins
	mov	byte[explody], 1
	mov     byte[player], 'X' 		;Change winner to X
	movzx   eax, byte[obomb]
	mov     bl, '2'
	mov     [loc3+eax], bl 			;Put a 2 where O's unexploded bomb is
	movzx   eax, byte[usr]
	mov     bl, '!'
	mov     [loc3+eax], bl			;Put explosion symbol on the last position chosen
	jmp     win3
no_explode3:
ret

find_match3: ;Check all win conditions for a 3x3 board (HaRd CoDeD LOL)
	mov     bl, byte[player] 	;bl now holds the symbol of the current player ;Fallthrough
case_3a:				;Case 3a = (0 1 2)
	mov     byte[itermat], 0
loop_3a:
	mov     al, [itermat]
	cmp     byte[loc3+eax], bl 	;Check if the symbol at that area is the current player symbol
	jne     case_3b			;If not go to next case
	inc     byte[itermat]
	cmp     byte[itermat], 3
	je      win3			;If all 3 symbols are the current player symbol, the current player wins
	jmp     loop_3a
case_3b:
	mov     byte[itermat], 0 	;Case 3b = (0 3 6)
loop_3b:
	mov     al, [itermat]
	cmp     byte[loc3+eax], bl
	jne     case_3c
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 9
	je      win3
	jmp     loop_3b
case_3c:
	mov     byte[itermat], 0 	;Case 3c = (0 4 8)
loop_3c:
	mov     al, [itermat]
	cmp     byte[loc3+eax], bl
	jne     case_3d
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 12
	je      win3
	jmp     loop_3c	
case_3d:	
	mov     byte[itermat], 0 	;Case 3d = (1 4 7)
loop_3d:
	mov     al, [itermat]
	cmp     byte[loc3+eax+1], bl
	jne     case_3e
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 9
	je      win3
	jmp     loop_3d
case_3e:
	mov     byte[itermat], 0 	;Case 3e = (2 4 6)
loop_3e:	
	mov     al, [itermat]
	cmp     byte[loc3+eax+2], bl
	jne     case_3f
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 6
	je      win3
	jmp     loop_3e
case_3f:
	mov     byte[itermat], 0 	;Case 3f = (2 5 8)
loop_3f:
	mov     al, [itermat]
	cmp     byte[loc3+eax+2], bl
	jne     case_3g
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 9
	je      win3
	jmp     loop_3f
case_3g:
	mov     byte[itermat], 0 	;Case 3g = (3 4 5)
loop_3g:	
	mov     al, [itermat]
	cmp     byte[loc3+eax+3], bl
	jne     case_3h
	inc     byte[itermat]
	cmp     byte[itermat], 3
	je      win3
	jmp     loop_3g
case_3h:
	mov     byte[itermat], 0 	;Case 3h = (6 7 8)
loop_3h:
	mov     al, [itermat]
	cmp     byte[loc3+eax+6], bl
	jne     out			;If there is no matches detected, return to the game
	inc     byte[itermat]
	cmp     byte[itermat], 3
	je      win3
	jmp     loop_3h
out:
ret

win3:
	mov     ecx, finalb
	mov     edx, finalb_l
	call 	print_int
	cmp	byte[explody], 1
	je 	win3bomb
win3nobomb:	
	movzx   eax, byte[xbomb]
	mov     bl, '1'			;Put a 1 where X's bomb was
	mov     [loc3+eax], bl
	movzx   eax, byte[obomb]
	mov     bl, '2'
	mov     [loc3+eax], bl 		;Put a 2 where O's unexploded bomb is
win3bomb:	
	call    print_board3		;Print the final board
	
	cmp     byte[player], 'X' 	;Find who won the game
	je      xwins3
	cmp     byte[player], 'O'
	je      owins3
owins3:
	mov     ecx, owin		;Say that O won the game
	mov     edx, owin_l
	call    print_int
	call    abort
xwins3:
	mov     ecx, xwin		;Say that X won the game
	mov     edx, xwin_l
	call    print_int
	call    abort
	
tie3:	
	mov     ecx, finalb	
	mov     edx, finalb_l
	call    print_int
	call    print_board3		;Print ou the final board
	
	mov     ecx, tie		;Say that the game ended in a tie
	mov     edx, tie_l
	call    print_int
	call    abort
	
player3:			;Current player turn on 3x3 board
	call    get_valid3 	;Get valid player choice
	movzx   eax, byte[usr] 	;Update position with 'X'
	mov     bl, [player]
	mov     [loc3+eax], bl
ret

get_valid3:
	mov     ecx, currb 	;"Current board: "
	mov     edx, currb_l
	call    print_int
	
	call    print_board3 	;Print the current game board
	
	mov     ecx, usr 	;Get user input and store in usr
	mov     edx, 3
	call    read_int
	call	convert_int	;Convert input to decimal
	
	movzx   eax, byte[usr] 	;Change ASCII to decimal
	;;;  Check if input is 0-8
	cmp     al, 0
	jl      err3
	cmp     al, 8
	jg      err3
	;;;  Check if input is taken
	cmp     byte[loc3+eax], ' '
	jne     err3
ret

err3:
	mov ecx, nvalid
	mov edx, nvalid_l
	call print_int
	jmp get_valid3

print_board3:
	mov     byte[iter], 0 		;Set outer row iterator to 0
	mov     byte[msgpos], 0		;Set board iterator to 0
	call    print_loop3
ret
print_loop3:
	mov     byte[rowiter], 0 	;Set inner row iterator to 0
	cmp     byte[iter], 3	 	;Exit loop if 3 rows printed
	je      exit_loop
	
	call    print_row3
	cmp     byte[iter], 2 		;Don't print divider after last row
	jne     print_divider3
	
	inc     byte[iter]
	jmp     print_loop3
print_row3:
	call    update_row3 		;Put symbols in the board
	mov     ecx, brd3
	mov     edx, brd3_l
	call    print_int
ret
update_row3:
	cmp     byte[rowiter], 5 	;Exit loop if end of row (row is 5 chars long including | character)
	jge     exit_loop
	
	mov     al, [msgpos] 		;Position in board (0-8)
	mov     bl, [loc3+eax] 		;Get char at position
	mov     al, [rowiter]
	mov     [brd3+eax], bl 		;Write char to the board
	
	inc     byte[rowiter] 		;Inc twice to skip |
	inc     byte[rowiter]
	inc     byte[msgpos]
	jmp     update_row3
ret
print_divider3:
	mov     ecx, brd3ln
	mov     edx, brd3ln_l
	call    print_int
	inc     byte[iter]
	jmp     print_loop3
	
place_bomb3x:
	mov     ecx, bombx
	mov     edx, bombx_l
	call    print_int
	
	call    get_valid3	;Make sure the bomb is within 0-8
	
	mov     eax, [usr]	;Move the location choice to xbomb
	mov     [xbomb], eax
ret

place_bomb3o:
	mov     ecx, bombo
	mov     edx, bombo_l
	call    print_int
	
	call    get_valid3	;Make sure the bomb is within 0-8
	
	mov     eax, [usr]	;Move the location choice to obomb
	mov     [obomb], eax
ret

exit_loop:
ret

	;; /////////////////////////
	;; 4x4 Board Subroutines 
	;; /////////////////////////
play4:
	mov	byte[explody], 0
	call    place_bomb4x	;Each player place a bomb before playing
	call    place_bomb4o
start4:
	mov     ecx, px4
	mov     edx, px4_l
	call    print_int
	
	mov     byte[player], 'X' 	;Player X's turn
	call    player4			
	call    check_bomb4		;Check if Player X exploded player O's bomb
	call    find_match4		;Check if Player X got a match
	
	mov     ecx, po4
	mov     edx, po4_l
	call    print_int
	
	mov     byte[player], 'O' 	;Player O's turn
	call    player4			
	call    check_bomb4		;Check if Player O exploded player X'x bomb
	call    find_match4		;Check if Player O got a match
	
	inc     byte[turns]
	cmp     byte[turns], 8		;Game end in a tie if Player O has had 8 turns
	je      tie4
	jmp     start4

check_bomb4:
	;;;  Execute based on current player
	cmp     byte[player], 'X'
	je      currx4
	cmp     byte[player], 'O'
	je      curro4
currx4:
	;;;  Know that current player is X
	;;;  Need to know if the position chosen in usr is same as obomb
	;;;  If true jump to win3
	;;;  If false ret
	movzx   eax, byte[usr]
	sub     al, '0'
	movzx   ebx, byte[obomb]
	sub     bl, '0'
	cmp     al, bl
	je      explodex4
	jmp     no_explode4
curro4:
	;;;  Know that the current player is O
	;;;  Need to know if the position chosen in usr is same as xbomb
	;;;  If true jump to win3
	;;;  If false ret
	movzx   eax, byte[usr]
	sub     al, '0'
	movzx   ebx, byte[xbomb]
	sub     bl, '0'
	cmp     al, bl
	je      explodeo4
	jmp     no_explode4
explodex4:
	;;;  O's bomb exploded so O wins
	mov	byte[explody], 1
	mov     byte[player], 'O' 		;Make O the winner
	movzx   eax, byte[xbomb]
	mov     bl, '1'				;Indicate where X's unexploded bomb is with a 1
	mov     [loc4+eax], bl
	movzx	eax, byte[usr]
	mov	bl, '@'
	mov	[loc4+eax], bl			;Put explosion symbol in last position chosen
	jmp     win4
explodeo4:
	;;;  X's bomb exploded so X wins
	mov	byte[explody], 1
	mov     byte[player], 'X' 		;Make X the winner
	movzx   eax, byte[obomb]
	mov     bl, '2'				;Indicate where O's unexploded bomb is with a 2
	mov     [loc4+eax], bl
	movzx   eax, byte[usr]
	mov     bl, '!'
	mov     [loc4+eax], bl
	jmp     win4
no_explode4:
ret
	
find_match4:				;Check if any win conditions are met (hArD coDED)
	mov     bl, byte[player]
case_4a:
	mov     byte[itermat], 0 	;Case 4a = (0 1 2 3)
loop_4a:
	mov     al, [itermat]
	cmp     byte[loc4+eax], bl 	;Check if the position contains the current player's symbol
	jne     case_4b			;If not, go to next case
	inc     byte[itermat]
	cmp     byte[itermat], 4 	
	je      win4			;If 4 symbols are found, the current player wins the game
	jmp     loop_4a
case_4b:
	mov     byte[itermat], 0 	;Case 4b = (4 5 6 7)
loop_4b:
	mov     al, [itermat]
	cmp     byte[loc4+4+eax], bl
	jne     case_4c
	inc     byte[itermat]
	cmp     byte[itermat], 4
	je      win4
	jmp     loop_4b
case_4c:
	mov     byte[itermat], 0 	;Case 4c = (8 9 10 11)
loop_4c:
	mov     al, [itermat]
	cmp     byte[loc4+8+eax], bl
	jne     case_4d
	inc     byte[itermat]
	cmp     byte[itermat], 4
	je      win4
	jmp     loop_4c
case_4d:	
	mov     byte[itermat], 0 	;Case 4d = (12 13 14 15)
loop_4d:	
	mov     al, [itermat]
	cmp     byte[loc4+12+eax], bl
	jne     case_4e
	inc     byte[itermat]
	cmp     byte[itermat], 4
	je      win4
	jmp     loop_4d
case_4e:
	mov     byte[itermat], 0 	;Case 4e = (0 4 8 12)
loop_4e:
	mov     al, [itermat]
	cmp     byte[loc4+eax], bl
	jne     case_4f
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 16
	je      win4
	jmp     loop_4e
case_4f:
	mov     byte[itermat], 0 	;Case 4f = (1 5 9 13)
loop_4f:
	mov     al, [itermat]
	cmp     byte[loc4+1+eax], bl
	jne     case_4g
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 16
	je      win4
	jmp     loop_4f
case_4g:
	mov     byte[itermat], 0 	;Case 4g = (2 6 10 14)	
loop_4g:	
	mov     al, [itermat]
	cmp     byte[loc4+2+eax], bl
	jne     case_4h
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 16
	je      win4
	jmp     loop_4g
case_4h:
	mov     byte[itermat], 0 	;Case 4h = (3 7 11 15)
loop_4h:
	mov     al, [itermat]
	cmp     byte[loc4+3+eax], bl
	jne     case_4i
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 16
	je      win4
	jmp     loop_4h
case_4i:
	mov     byte[itermat], 0 	;Case 4i = (0 5 10 15)
loop_4i:
	mov     al, [itermat]
	cmp     byte[loc4+eax], bl
	jne     case_4j
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 20
	je      win4
	jmp     loop_4i
case_4j:
	mov     byte[itermat], 0 	;Case 4j = (3 6 9 12)
loop_4j:	
	mov     al, [itermat]
	cmp     byte[loc4+3+eax], bl
	jne     out
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 12
	je      win4
	jmp     loop_4j
	
win4:	
	mov     ecx, finalb
	mov     edx, finalb_l
	call    print_int
	cmp	byte[explody], 1
	je 	win4bomb
win4nobomb:	
        movzx   eax, byte[xbomb]
	mov     bl, '1'			;Put a 1 where X's bomb was
	mov     [loc4+eax], bl
	movzx   eax, byte[obomb]
	mov     bl, '2'
	mov     [loc4+eax], bl 		;Put a 2 where O's unexploded bomb is
win4bomb:
	call 	print_board4	  	;Print final board
	cmp     byte[player], 'X' 	;Find which player won the game 
	je      xwins4
	cmp     byte[player], 'O'
	je      owins4
owins4:	
	mov     ecx, owin		;Indicate that O won the game
	mov     edx, owin_l
	call    print_int
	call    abort
xwins4:
	mov     ecx, xwin		;Indicate that X won the game	
	mov     edx, xwin_l
	call    print_int
	call    abort
	
tie4:	
	mov     ecx, finalb		;Print the final board and indicate that the gae was a tie
	mov     edx, finalb_l
	call    print_int
	call    print_board4
	
	mov     ecx, tie
	mov     edx, tie_l
	call    print_int
	call    abort

player4:			;Current player turn on 4x4 board
	call    get_valid4 	;Get valid player choice (0-15)
	movzx   eax, byte[usr] 	
	mov     bl, [player]
	mov     [loc4+eax], bl	;Put the player's symbol in the spot they have chosen
ret

get_valid4:
        mov     ecx, currb
	mov     edx, currb_l
	call    print_int
	
	call    print_board4 ;Print the current game board
	
	mov     ecx, usr 		;Get user input and store in usr
	mov     edx, 3
	call    read_int
	
	call    convert_int		;Convert input to decimal
	movzx   eax, byte[usr]
	;;;  Check if input is 0-15
	cmp     al, 0
	jl      err4
	cmp     al, 15
	jg      err4
	;;;  Check if input is taken
	cmp     byte[loc4+eax], ' '
	jne     err4
ret
	
err4:
	mov 	ecx, nvalid
	mov 	edx, nvalid_l
	call 	print_int
	jmp 	get_valid4

print_board4:
	mov     byte[iter], 0 		;Set outer row iterator to 0
	mov     byte[msgpos], 0		;Set board iterator to 0
	call    print_loop4
ret
print_loop4:
	mov     byte[rowiter], 0 	;Set inner row iterator to 0
	cmp     byte[iter], 4	 	;Exit loop if 4 rows printed
	je      exit_loop
	
	call    print_row4
	cmp     byte[iter], 3 		;Don't print divider after last row
	jne     print_divider4
	
	inc     byte[iter]
	jmp     print_loop4
print_row4:
	call    update_row4 		;Put symbols in board
	mov     ecx, brd4
	mov     edx, brd4_l
	call    print_int
ret
update_row4:
	cmp     byte[rowiter], 7 	;Exit loop if end of row
	jge     exit_loop
	
	mov     al, [msgpos] 		;Position in board (0-15)
	mov     bl, [loc4+eax] 		;Get char at position
	mov     al, [rowiter]
	mov     [brd4+eax], bl 		;Write char to board
	
	inc     byte[rowiter] 		;Inc twice to skip |
	inc     byte[rowiter]
	inc     byte[msgpos]
	
	jmp     update_row4
ret
print_divider4:
	mov     ecx, brd4ln
	mov     edx, brd4ln_l
	call    print_int
	
	inc     byte[iter]
	jmp     print_loop4
	
place_bomb4x:
	mov     ecx, bombx
	mov     edx, bombx_l
	call    print_int
	
	call    get_valid4	;Check if the bomb is between 0-15
	
	mov     eax, [usr]
	mov     [xbomb], eax	;Put bomb location in xbomb
ret
place_bomb4o:
	mov     ecx, bombo
	mov     edx, bombo_l
	call    print_int
	
	call    get_valid4	;Check if the bomb is between 0-15
	
	mov     eax, [usr]
	mov     [obomb], eax	;Put bomb location in obomb
ret
	
	
	;; /////////////////////////
	;; 5x5 Board Subroutines
	;; /////////////////////////
play5:
	mov	byte[explody], 0
	call    place_bomb5x		;Players place bomb before sarting the game
	call    place_bomb5o
start5:
	mov     ecx, px5	
	mov     edx, px5_l
	call    print_int
	
	mov     byte[player], 'X' 	;Player X's turn
	call    player5			;Get player X's choice
	call    check_bomb5		;Check if player X exploded player O's bomb
	call    find_match5		;Check if a match is found
	
	inc     byte[turns]
	cmp     byte[turns], 13		;Game ends in a tie if player X has had 13 turns
	je      tie5
	
	mov     ecx, po5
	mov     edx, po5_l
	call    print_int
	
	mov     byte[player], 'O' 	;Player O's turn
	call    player5
	call    check_bomb5
	call    find_match5
	jmp     start5

check_bomb5:
	;;;  Execute based on current player
	cmp     byte[player], 'X'
	je      currx5
	cmp     byte[player], 'O'
	je      curro5
currx5:	
	;;;  Know that current player is X
	;;;  Need to know if the position chosen in usr is same as obomb
	;;;  If true jump to win3
	;;;  If false ret
	movzx   eax, byte[usr]
	sub     al, '0'
	movzx   ebx, byte[obomb]
	sub     bl, '0'
	cmp     al, bl
	je      explodex5
	jmp     no_explode5
curro5:
	;;;  Know that the current player is O
	;;;  Need to know if the position chosen in usr is same as xbomb
	;;;  If true jump to win3
	;;;  If false ret
	movzx   eax, byte[usr]
	sub     al, '0'
	movzx   ebx, byte[xbomb]
	sub     bl, '0'
	cmp     al, bl
	je      explodeo5
	jmp     no_explode5
explodex5:
	;;;  O's bomb exploded so O wins
	mov	byte[explody], 1
	mov     byte[player], 'O'
	movzx   eax, byte[xbomb]
	mov     bl, '1'
	mov     [loc5+eax], bl 		;Show where the unexploded bomb is
	movzx   eax, byte[usr]
	mov     bl, '@'
	mov     [loc5+eax], bl		;Put explosion symbol
	jmp     win5
explodeo5:
	;;;  X's bomb exploded so X wins
	mov	byte[explody], 1
	mov     byte[player], 'X'
	movzx   eax, byte[obomb]
	mov     bl, '2'
	mov     [loc5+eax], bl
	movzx   eax, byte[usr]
	mov     bl, '!'
	mov     [loc5+eax], bl
	jmp     win5
no_explode5:
ret
	
find_match5:				;Check if there are any matches (HARD CODED UwU)
	mov     bl, byte[player]
case_5a:
	mov     byte[itermat], 0 	;Case 5a = (0 1 2 3 4)
loop_5a:	
	mov     al, [itermat]
	cmp     byte[loc5+eax], bl
	jne     case_5b
	inc     byte[itermat]
	cmp     byte[itermat], 5
	je      win5
	jmp     loop_5a
case_5b:
	mov     byte[itermat], 0 	;Case 5b = (5 6 7 8 9)
loop_5b:
	mov     al, [itermat]
	cmp     byte[loc5+5+eax], bl
	jne     case_5c
	inc     byte[itermat]
	cmp     byte[itermat], 5
	je      win5
	jmp     loop_5b
case_5c:	
	mov     byte[itermat], 0 	;Case 5c = (10 11 12 13 14)
loop_5c:	
	mov     al, [itermat]
	cmp     byte[loc5+10+eax], bl
	jne     case_5d
	inc     byte[itermat]
	cmp     byte[itermat], 5
	je      win5
	jmp     loop_5c
case_5d:
	mov     byte[itermat], 0 	;Case 5d = (15 16 17 18 19)
loop_5d:	
	mov     al, [itermat]
	cmp     byte[loc5+15+eax], bl
	jne     case_5e
	inc     byte[itermat]
	cmp     byte[itermat], 5
	je      win5
	jmp     loop_5d
case_5e:	
	mov     byte[itermat], 0 	;Case 5e = (20 21 22 23 24)
loop_5e:
	mov     al, [itermat]
	cmp     byte[loc5+20+eax], bl
	jne     case_5f
	inc     byte[itermat]
	cmp     byte[itermat], 5
	je      win5
	jmp     loop_5e
case_5f:
	mov     byte[itermat], 0 	;Case 5f = (0 5 10 15 20)
loop_5f:	
	mov     al, [itermat]
	cmp     byte[loc5+eax], bl
	jne     case_5g
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 25
	je      win5
	jmp     loop_5f
case_5g:
	mov     byte[itermat], 0 	;Case 5g = (1 6 11 16 21)
loop_5g:
	mov     al, [itermat]
	cmp     byte[loc5+1+eax], bl
	jne     case_5h
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 25
	je      win5
	jmp     loop_5g
case_5h:
	mov     byte[itermat], 0 	;Case 5h = (2 7 12 17 22)
loop_5h:
	mov     al, [itermat]
	cmp     byte[loc5+2+eax], bl
	jne     case_5i
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 25
	je      win5
	jmp     loop_5h
case_5i:
	mov     byte[itermat], 0 	;Case 5i = (3 8 13 18 23)
loop_5i:	
	mov     al, [itermat]
	cmp     byte[loc5+3+eax], bl
	jne     case_5j
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 25
	je      win5
	jmp     loop_5i
case_5j:
	mov     byte[itermat], 0 	;Case 5j = (4 9 14 20 24)
loop_5j:
	mov     al, [itermat]
	cmp     byte[loc5+4+eax], bl
	jne     case_5k
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 25
	je      win5
	jmp     loop_5j
case_5k:
	mov     byte[itermat], 0 	;Case 5k = (0 6 12 18 24)	
loop_5k:	
	mov     al, [itermat]
	cmp     byte[loc5+eax], bl
	jne     case_5l
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 30
	je      win5
	jmp     loop_5k
case_5l:
	mov     byte[itermat], 0 	;Case 5l = (4 8 12 16 20)
loop_5l:	
	mov     al, [itermat]
	cmp     byte[loc5+4+eax], bl
	jne     out			;No matches found so go back to playing the game
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	inc     byte[itermat]
	cmp     byte[itermat], 20
	je      win5
	jmp     loop_5l

win5:
	mov     ecx, finalb
	mov     edx, finalb_l
	call    print_int

	cmp	byte[explody], 1
	je 	win5bomb
win5nobomb:	
	movzx   eax, byte[xbomb]
	mov     bl, '1'			;Put a 1 where X's bomb was
	mov     [loc5+eax], bl
	movzx   eax, byte[obomb]
	mov     bl, '2'
	mov     [loc5+eax], bl 		;Put a 2 where O's unexploded bomb is
win5bomb:
	call	print_board5
	cmp     byte[player], 'X' 	;Find who won
	je      xwins5
	cmp     byte[player], 'O'
	je      owins5
owins5:	
	mov     ecx, owin		;Print out that O won
	mov     edx, owin_l
	call    print_int
	call    abort
xwins5:
	mov     ecx, xwin		;Print out that X won
	mov     edx, xwin_l
	call    print_int
	call    abort
	
tie5:
	mov     ecx, finalb		;Print out that the game ended in a tie
	mov     edx, finalb_l
	call    print_int
	call    print_board5
	
	mov     ecx, tie
	mov     edx, tie_l
	call    print_int
	call    abort
	
player5:			;Current player turn on 5x5 board
	call    get_valid5 	;Get valid player choice (0-24)
	movzx   eax, byte[usr] 	
	mov     bl, [player]
	mov     [loc5+eax], bl 	;Put current player symbol in the chose location on the board
ret

get_valid5:
	mov     ecx, currb
	mov     edx, currb_l
	call    print_int
	
	call    print_board5 ;Print the current game board
	
	mov     ecx, usr 	;Get user input and store in usr
	mov     edx, 3
	call    read_int
	
	call    convert_int
	movzx   eax, byte[usr]
	;;;  Check if input is 0-24
	cmp     al, 0
	jl      err5
	cmp     al, 24
	jg      err5
	;;;  Check if input is taken
	cmp     byte[loc5+eax], ' '
	jne     err5
ret
	
err5:
	mov     ecx, nvalid
	mov     edx, nvalid_l
	call    print_int
	jmp     get_valid5
	
print_board5:
	mov     byte[iter], 0 		;Set outer row iterator to 0
	mov     byte[msgpos], 0		;Set board iterator to 0
	call    print_loop5
ret
print_loop5:
	mov     byte[rowiter], 0 	;Set inner row iterator to 0
	cmp     byte[iter], 5	 	;Exit loop if 5 rows printed
	je      exit_loop
	
	call    print_row5
	cmp     byte[iter], 4 		;Don't print divider after last row
	jne     print_divider5
	
	inc     byte[iter]
	jmp     print_loop5
print_row5:
	call    update_row5 		;Put symbols in board
	mov     ecx, brd5
	mov     edx, brd5_l
	call    print_int
ret
update_row5:
	cmp     byte[rowiter], 9 	;Exit loop if end of row
	jge     exit_loop
	
	mov     al, [msgpos] 		;Position in board (0-24)
	mov     bl, [loc5+eax] 		;Get char at position
	mov     al, [rowiter]
	mov     [brd5+eax], bl 		;Write char to table
	
	inc     byte[rowiter] 		;Inc twice to skip |
	inc     byte[rowiter]
	inc     byte[msgpos]
	
	jmp     update_row5
ret
print_divider5:
	mov     ecx, brd5ln
	mov     edx, brd5ln_l
	call    print_int
	
	inc     byte[iter]
	jmp     print_loop5
	

place_bomb5x:
	mov     ecx, bombx
	mov     edx, bombx_l
	call    print_int
	
	call    get_valid5 	;Bomb must be between 0-24
	
	mov     eax, [usr]
	mov     [xbomb], eax	;Store location in xbomb
ret
place_bomb5o:
	mov     ecx, bombo
	mov     edx, bombo_l
	call    print_int
	
	call    get_valid5	;Bomb must be between 0-24
	
	mov     eax, [usr]
	mov     [obomb], eax	;Store bomb in obomb
ret
	
	;; //////////////////////
	;; END OF SUBROUTINES
	;; //////////////////////
	
_start:
	mov 	ecx, debug  	;DEBUGGING NOT IMPLEMENTED!!!
	mov	edx, debug_l
	call	print_int

	mov	ecx, usr
	mov	edx, 2
	call 	read_int

	
	call    get_size			;Will terminate if invalid board size chosen
	;;;  Find which board to play on.
	movzx   eax, byte[bsize]
	sub     al, '0'
	
	mov     byte[turns], 0 			;Counts how many turns taken
	
	cmp     al, 3	;Play on 3x3 board
	je      play3
	
	cmp     al, 4	;Play on 4x4 board
	je      play4
	
	cmp     al, 5	;Play on 5x5 board
	je      play5
	
	call    abort
	
