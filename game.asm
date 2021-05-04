#####################################################################
#
# CSCB58 Winter 2021 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Simon Y. Chau
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8 (update this as needed)
# - Unit height in pixels: 8 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - All milestones have been completed
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Increase in difficulty as game progresses
#	- Objects will gradually become faster
# 2. Scoring system
#	- Out of 6 (very difficult to get the max score of 6)
#	- Score is displayed once the game ends (game over screen)
# 3. More advanced collision detection
#	- Head on collision takes about a third of the health bar
#	- A grazing collision takes about two pixels or about a sixteenth of the health bar
#	- It is possible to get something in between the above (trying to avoid the collision, etc.)
#	- There is more animation depending on the collision (your ship will flash red more)
#
# Link to video demonstration for final submission:
# - YouTube link: https://www.youtube.com/watch?v=4OutGOcvWQc&ab_channel=SimonChau
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, link in the YouTube description (if I remember to :^) )
#
# Any additional information that the TA needs to know:
# - Have fun playing the game!
#
#####################################################################

# Bitmap display starter code
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#

.eqv BASE_ADDRESS 0x10008000
.eqv RED 0x00ff0000
.eqv GREEN 0x00ff00
.eqv DARK_GREEN	0x005151
.eqv GREY 0x808080
.eqv BLACK 0x00000000
.eqv LIGHT_BLUE 0x00ADD8E6
.eqv LIGHT_PURPLE 0x006666FF
.eqv ORANGE 0x00FFA500
.eqv YELLOW 0x00ffff00
.eqv BRIGHT_YELLOW 0x00FFFF00
.eqv DARK_RED 0x008b0000
.eqv KEYBOARD_INPUT 0xffff0000
.eqv a_IN_ASCII 0x61
.eqv d_IN_ASCII 0x64
.eqv w_IN_ASCII 0x77
.eqv s_IN_ASCII 0x73
.eqv p_IN_ASCII 0x70

.data
ship_pos:	.word	3, 15				# the x and y position of the ship
object_pos:	.word	29, 1, 29, 15, 29, 30		# obj1 (x, y) . . . obj3 (x, y)
health_bar:	.word	31				# the y position of the health bar
score_tracker:	.word	0				# keeps track of the players score
redraw_ship:	.word	0				# 1 if the ship needs to be redrawn. 0 otherwise

.text
addi $sp $sp -4		# move stack pointer one word
la $t0 GREEN		# $t0 holds the green colour code
sw $t0 0($sp)		# push a word onto the stack
jal ship_draw_func	# call ship_draw_func

addi $sp $sp -4		# move stack pointer one word
la $t0 GREY		# $t0 holds the grey colour code
sw $t0 0($sp)		# push a word onto the stack
jal object_draw_func	# call object_draw_func

addi $sp $sp -4		# move stack pointer one word
la $t0 RED		# $t0 holds the red colour code
sw $t0 0($sp)		# push a word onto the stack
jal full_health_bar	# call full_health_bar

li $v0, 32
li $a0, 1000 		# wait 1000 milliseconds
syscall

main:	li $t9, KEYBOARD_INPUT	# check if the user has typed
	lw $t8, 0($t9)
	beq $t8, 1, key_pressed
	jal update_objects	# call update_object func
	la $t9 redraw_ship	# $t9 = address of redraw_ship
	lw $t8 0($t9)		# $t8 = value in redraw_ship
	beq $zero $t8 loop_main
	sw $zero 0($t9)		# store 0 into redraw_ship
	addi $sp $sp -4		# move stack pointer one word
	la $t0 GREEN		# $t0 holds the green colour code
	sw $t0 0($sp)		# push a word onto the stack
	jal ship_draw_func	# call ship_draw_func
	
loop_main:	la $t0 score_tracker	# $t0 = score_keeper address
		lw $t0 0($t0)		# $t0 = # of times obj2 has reset (raw score)
		div $t0 $t0 5
		
		li $t1 12
		beq $t0 $t1 end_screen	# check if max score has been achieved
		li $v0, 32
		li $t1 50
		sub $a0 $t1 $t0 	# wait (50 - $t0) milliseconds
		syscall
	
		j main
	
key_pressed:	jal update_ship
ship_updated:	addi $sp $sp -4		# move stack pointer one word
		la $t0 GREEN		# $t0 holds the green colour code
		sw $t0 0($sp)		# push a word onto the stack
		jal ship_draw_func	# call ship_draw_func
		
		j main
		
	
### updating and painting the objects ###
object_draw_func:	lw $t0 0($sp)		# pop off the 'colour' argument off the stack
			addi $sp $sp 4		# move stack pointer one word
			
			addi $sp $sp -4		# move stack pointer one word
			sw $ra 0($sp)		# store the ra before using another jal call

			### object1
			la $t4 BASE_ADDRESS	# $t4 holds the base address
			la $t5 object_pos	# $t5 = object_pos address
			lw $t5 4($t5)		# $t5 = y
			sll $t6 $t5 5		# $t6 = y * 32
			la $t5 object_pos	# $t5 = object_pos address
			lw $t5 0($t5)		# $t5 = x
			add $t6 $t6 $t5		# $t6 = y * 32 + x
			sll $t6 $t6 2		# $t6 = (y * 32 + x) * 4
			add $t3 $t6 $t4		# $t3 = (y * 32 + x) * 4 + BASE_ADDRESS
			
			add $a0 $zero $t3	# put $t3 into $a0
			add $a1 $zero GREEN	# put green into $a1
			la $a2 DARK_RED
			
			jal check_collision
			addi $a0 $t3 8		# put $t3 + 8 into $a0
			jal check_collision
	
			sw $t0 0($t3)		# make the object the given colour
			sw $t0 8($t3)		# make the object the given colour
			
			addi $t3 $t3 -124	# back pixel
			
			add $a0 $zero $t3	# put $t3 into $a0
			
			jal check_collision
		
			sw $t0 0($t3)		# make the object the given colour
			
			addi $t3 $t3 124	# undo from before
			addi $t3 $t3 132	# back pixel
			
			add $a0 $zero $t3	# put $t3 into $a0
			
			jal check_collision
		
			sw $t0 0($t3)		# make the object the given colour
			
			### object2
			la $t5 object_pos	# $t5 = object_pos address
			lw $t5 12($t5)		# $t5 = y
			sll $t6 $t5 5		# $t6 = y * 32
			la $t5 object_pos	# $t5 = object_pos address
			lw $t5 8($t5)		# $t5 = x
			add $t6 $t6 $t5		# $t6 = y * 32 + x
			sll $t6 $t6 2		# $t6 = (y * 32 + x) * 4
			add $t3 $t6 $t4		# $t3 = (y * 32 + x) * 4 + BASE_ADDRESS
			
			add $a0 $zero $t3	# put $t3 into $a0
			
			jal check_collision
			addi $a0 $t3 8		# put $t3 + 8 into $a0
			jal check_collision			
	
			sw $t0 0($t3)		# make the object the given colour
			sw $t0 8($t3)		# make the object the given colour
			
			addi $t3 $t3 -124	# back pixel
			
			add $a0 $zero $t3	# put $t3 into $a0
			
			jal check_collision
		
			sw $t0 0($t3)		# make the object the given colour
		
			addi $t3 $t3 124	# undo from before
			addi $t3 $t3 132	# back pixel
			
			add $a0 $zero $t3	# put $t3 into $a0
			
			jal check_collision
		
			sw $t0 0($t3)		# make the object the given colour
			
			### object3
			la $t5 object_pos	# $t5 = object_pos address
			lw $t5 20($t5)		# $t5 = y
			sll $t6 $t5 5		# $t6 = y * 32
			la $t5 object_pos	# $t5 = object_pos address
			lw $t5 16($t5)		# $t5 = x
			add $t6 $t6 $t5		# $t6 = y * 32 + x
			sll $t6 $t6 2		# $t6 = (y * 32 + x) * 4
			add $t3 $t6 $t4		# $t6 = (y * 32 + x) * 4 + BASE_ADDRESS
			
			add $a0 $zero $t3	# put $t3 into $a0

			jal check_collision
			addi $a0 $t3 8		# put $t3 + 8 into $a0
			jal check_collision
	
			sw $t0 0($t3)		# make the object the given colour
			sw $t0 8($t3)		# make the object the given colour
			
			addi $t3 $t3 -124	# back pixel
			
			add $a0 $zero $t3	# put $t3 into $a0

			jal check_collision
		
			sw $t0 0($t3)		# make the object the given colour
		
			addi $t3 $t3 124	# undo from before
			addi $t3 $t3 132	# back pixel
			
			add $a0 $zero $t3	# put $t3 into $a0

			jal check_collision
		
			sw $t0 0($t3)		# make the object the given colour
			
			lw $ra 0($sp)		# load back the ra
			addi $sp $sp 4		# move stack pointer one word
		
			jr $ra			# return
			
objects_updated:	addi $sp $sp -4			# move stack pointer one word
			la $t0 GREY			# $t0 holds the grey colour code
			sw $t0 0($sp)			# push a word onto the stack
			jal object_draw_func		# call object_draw_func
			
			lw $ra 0($sp)			# load the ra
			addi $sp $sp 4			# move stack pointer one word
			jr $ra

update_objects:		addi $sp $sp -4			# move stack pointer one word
			sw $ra 0($sp)			# store the ra before using another jal call
			
			addi $sp $sp -4			# move stack pointer one word
			la $t0 BLACK			# $t0 holds the black colour code
			sw $t0 0($sp)			# push a word onto the stack
			jal object_draw_func		# call ship_draw_func
			jal update_object1		# call update_object1
			jal update_object2		# call update_object2
			jal update_object3		# call update_object3
			j objects_updated		# jump to objects updated
			
update_object1:		la $t0 object_pos		# $t0 = object_pos address
			lw $t1 0($t0)			# $t1 = x
			addi $t1 $t1 -2			# $t1 = x - 2
			blt $t1 $zero reset_object1	# check if object is at the edge
			sw $t1 0($t0)			# updated x value
			jr $ra

reset_object1:		li $t1 29
			sw $t1 0($t0)			# setting x to 29
			
			li $v0, 42			
			li $a0, 0
			li $a1, 29
			syscall
			add $t1 $zero $a0
			addi $t1 $t1 1
			sw $t1 4($t0)			# setting y some number between 1 - 30
			jr $ra	

update_object2:		lw $t1 8($t0)			# $t1 = x
			addi $t1 $t1 -1			# $t1 = x - 1
			li $t2 1			# $t2 = 1
			blt $t1 $t2 reset_object2	# check if object is at the edge
			sw $t1 8($t0)			# updated x value
			jr $ra

reset_object2:		li $t1 29
			sw $t1 8($t0)			# setting x to 29
			
			li $v0, 42			
			li $a0, 0
			li $a1, 29
			syscall
			add $t1 $zero $a0
			addi $t1 $t1 1
			sw $t1 12($t0)			# setting y some number between 1 - 30
			
			### we will be incrementing the score_tracker here
			la $t1 score_tracker		# $t1 = score_tracker address
			lw $t2 0($t1)			# $t2 = score
			addi $t2 $t2 1			# $t2 incremented by 1
			sw $t2 0($t1)			# update the score
			### incrementing done
			
			jr $ra
			
update_object3:		lw $t1 16($t0)			# $t1 = x
			addi $t1 $t1 -2			# $t1 = x - 2
			blt $t1 $zero reset_object3	# check if object is at the edge
			sw $t1 16($t0)			# updated x value
			jr $ra
			
reset_object3:		li $t1 29
			sw $t1 16($t0)			# setting x to 29
			
			li $v0, 42			
			li $a0, 0
			li $a1, 29
			syscall
			add $t1 $zero $a0
			addi $t1 $t1 1
			sw $t1 20($t0)			# setting y some number between 1 - 30
			jr $ra
	
					
### updating and painting the ship ###
ship_draw_func:	lw $t0 0($sp)		# pop off the 'colour' argument off the stack
		addi $sp $sp 4		# move stack pointer one word

		la $t4 BASE_ADDRESS	# $t4 holds the base address
		la $t5 ship_pos		# $t5 = ship_pos address
		lw $t5 4($t5)		# $t5 = y
		sll $t6 $t5 5		# $t6 = y * 32
		la $t5 ship_pos		# $t5 = ship_pos address
		lw $t5 0($t5)		# $t5 = x
		add $t6 $t6 $t5		# $t6 = y * 32 + x
		sll $t6 $t6 2		# $t6 = (y * 32 + x) * 4
		add $t6 $t6 $t4		# $t6 = (y * 32 + x) * 4 + BASE_ADDRESS

		sw $t0 0($t6)		# make the ship the given colour
		
		addi $t6 $t6 -132	# the back pixel

		sw $t0 0($t6)		# make the ship the given colour
		sw $t0 -4($t6)		# make the ship the given colour
	
		addi $t6 $t6 132	# undo from before
		addi $t6 $t6 124	# the back pixel
		
		sw $t0 0($t6)		# make the ship the given colour
		sw $t0 -4($t6)		# make the ship the given colour

		jr $ra			# return

update_ship:	lw $t7, 4($t9) 				# this assumes $t9 is set to 0xfff0000 from before
		beq $t7, w_IN_ASCII, move_ship_w	# check what key user has inputted
		beq $t7, a_IN_ASCII, move_ship_a 	
		beq $t7, s_IN_ASCII, move_ship_s	
		beq $t7, d_IN_ASCII, move_ship_d
		beq $t7, p_IN_ASCII, reset
		jr $ra
		
move_ship_w:	addi $sp $sp -4			# move stack pointer one word
		sw $ra 0($sp)			# store the ra before using another jal call

		addi $sp $sp -4			# move stack pointer one word
		la $t0 BLACK			# $t0 holds the black colour code
		sw $t0 0($sp)			# push a word onto the stack
		jal ship_draw_func		# call ship_draw_func
		la $t0 ship_pos			# $t0 = ship_pos address
		lw $t1 4($t0)			# $t1 = y
		addi $t1 $t1 -1			# $t1 = y - 1
		li $t2 1			# $t2 = 1
		blt $t1 $t2 ship_updated	# check if y - 1 is valid
		sw $t1 4($t0)			# y ship_pos updated
		
		lw $ra 0($sp)			# load back the ra
		addi $sp $sp 4			# move stack pointer one word
		jr $ra				# return
	
move_ship_a:	addi $sp $sp -4			# move stack pointer one word
		sw $ra 0($sp)			# store the ra before using another jal call

		addi $sp $sp -4			# move stack pointer one word
		la $t0 BLACK			# $t0 holds the black colour code
		sw $t0 0($sp)			# push a word onto the stack
		jal ship_draw_func		# call ship_draw_func
		la $t0 ship_pos			# $t0 = ship_pos address
		lw $t1 0($t0)			# $t1 = x
		addi $t1 $t1 -1			# $t1 = x - 1
		li $t2 3			# $t2 = 2
		blt $t1 $t2 ship_updated	# check if x - 1 is valid
		sw $t1 0($t0)			# x ship_pos updated
		
		lw $ra 0($sp)			# load back the ra
		addi $sp $sp 4			# move stack pointer one word
		jr $ra				# return

move_ship_s:	addi $sp $sp -4			# move stack pointer one word
		sw $ra 0($sp)			# store the ra before using another jal call

		addi $sp $sp -4			# move stack pointer one word
		la $t0 BLACK			# $t0 holds the black colour code
		sw $t0 0($sp)			# push a word onto the stack
		jal ship_draw_func		# call ship_draw_func
		la $t0 ship_pos			# $t0 = ship_pos address
		lw $t1 4($t0)			# $t1 = y
		addi $t1 $t1 1			# $t1 = y + 1
		li $t2 30			# $t2 = 30
		bgt $t1 $t2 ship_updated	# check if y + 1 is valid
		sw $t1 4($t0)			# y ship_pos updated
		
		lw $ra 0($sp)			# load back the ra
		addi $sp $sp 4			# move stack pointer one word
		jr $ra				# return
		
move_ship_d:	addi $sp $sp -4			# move stack pointer one word
		sw $ra 0($sp)			# store the ra before using another jal call

		addi $sp $sp -4			# move stack pointer one word
		la $t0 BLACK			# $t0 holds the black colour code
		sw $t0 0($sp)			# push a word onto the stack
		jal ship_draw_func		# call ship_draw_func
		la $t0 ship_pos			# $t0 = ship_pos address
		lw $t1 0($t0)			# $t1 = x
		addi $t1 $t1 1			# $t1 = x + 1
		li $t2 31			# $t2 = 31
		bgt $t1 $t2 ship_updated	# check if x + 1 is valid
		sw $t1 0($t0)			# x ship_pos updated
		
		lw $ra 0($sp)			# load back the ra
		addi $sp $sp 4			# move stack pointer one word
		jr $ra				# return


### collision check ###
check_collision:	lw $t1 0($a0)		# load the colour
			beq $t1 $a1 collision	# check the colour
			jr $ra
			
collision:		add $t9 $zero $a2
			sw $t9 0($a0)
			li $v0, 32
			li $a0, 35 		# wait 35 milliseconds
			syscall

			addi $sp $sp -4		# move stack pointer one word
			sw $ra 0($sp)		# store the ra before using another jal call
			
			addi $sp $sp -4		# move stack pointer one word
			la $t9 DARK_GREEN	# $t0 holds the dark green colour code
			sw $t9 0($sp)		# push a word onto the stack
			
			jal decrease_health_bar	# decrease the health bar since a collision have occured
			
			la $t9 redraw_ship	# $t9 = address of redraw_ship
			li $t8 1		# $t8 = 1
			sw $t8 0($t9)		# store 1 into redraw_ship
			
			lw $ra 0($sp)		# load back the ra
			addi $sp $sp 4		# move stack pointer one word
			jr $ra
			

### health bar status & game over ###
full_health_bar:	lw $t0 0($sp)		# pop off the 'colour' argument off the stack
			addi $sp $sp 4		# move stack pointer one word
			
			la $t4 BASE_ADDRESS	# $t4 holds the base address
			la $t5 health_bar	# $t5 = health_bar address
			lw $t6 0($t5)		# $t6 = y
			
loop:			blt $t6 $zero loop_end	# looping condition
			sll $t7 $t6 7		# $t7 = (y * 32) * 4
			add $t7 $t7 $t4		# $t7 = (y * 32) * 4 + BASE_ADDRESS
			sw $t0 0($t7)		# make the health bar the given colour
			addi $t6 $t6 -1		# decrease y by 1
			j loop

loop_end:		sw $zero 0($t5)		# set y = 0
			jr $ra
			
decrease_health_bar:	lw $t1 0($sp)		# pop off the 'colour' argument off the stack
			addi $sp $sp 4		# move stack pointer one word
			
			la $t4 BASE_ADDRESS	# $t4 holds the base address
			la $t5 health_bar	# $t5 = health_bar address
			lw $t6 0($t5)		# $t6 = y
			
			sll $t7 $t6 7		# $t7 = (y * 32) * 4
			add $t7 $t7 $t4		# $t7 = (y * 32) * 4 + BASE_ADDRESS
			sw $t1 0($t7)		# make the health bar the given colour
			addi $t6 $t6 1		# increase y by 1
			sw $t6 0($t5)		# update the value of y
			
			li $t1 31
			bgt $t6 $t1 end_screen	# check if health bar is empty
			jr $ra
			
### reset the game ###
reset:	addi $sp $sp -4		# move stack pointer one word
	la $t0 BLACK		# $t0 holds the black colour code
	sw $t0 0($sp)		# push a word onto the stack
	jal ship_draw_func	# call ship_draw_func
	
	addi $sp $sp -4		# move stack pointer one word
	la $t0 BLACK		# $t0 holds the black colour code
	sw $t0 0($sp)		# push a word onto the stack
	jal object_draw_func	# call object_draw_func
	
	la $t5 health_bar	# $t5 = health_bar address
	li $t6 31		# $t6 = 31
	sw $t6 0($t5)		# y = 31
	addi $sp $sp -4		# move stack pointer one word
	la $t0 BLACK		# $t0 holds the black colour code
	sw $t0 0($sp)		# push a word onto the stack
	jal full_health_bar	# call full_health_bar
	
	la $t0 ship_pos		# $t0 is the address of the ship
	li $t1 3		# $t1 = 3
	sw $t1 0($t0)		# update the x position of the ship
	li $t1 15		#$t1 = 15
	sw $t1 4($t0)		# update the y position of the ship
	
	la $t0 object_pos	# $t0 is the address of object_pos
	li $t1 29		# $t1 = 29
	sw $t1 0($t0)		# update the x position of the object1
	sw $t1 8($t0)		# update the x position of the object2
	sw $t1 16($t0)		# update the x position of the object3
	li $t1 1		# $t1 = 1
	sw $t1 4($t0)		# update the y position of the object1
	li $t1 15		# $t1 = 15
	sw $t1 12($t0)		# update the y position of the object2
	li $t1 30		# $t1 = 30
	sw $t1 20($t0)		# update the y position of the object3
	
	addi $sp $sp -4		# move stack pointer one word
	la $t0 GREEN		# $t0 holds the green colour code
	sw $t0 0($sp)		# push a word onto the stack
	jal ship_draw_func	# call ship_draw_func

	addi $sp $sp -4		# move stack pointer one word
	la $t0 GREY		# $t0 holds the grey colour code
	sw $t0 0($sp)		# push a word onto the stack
	jal object_draw_func	# call object_draw_func

	la $t5 health_bar	# $t5 = health_bar address
	li $t6 31		# $t6 = 31
	sw $t6 0($t5)		# y = 31	
	addi $sp $sp -4		# move stack pointer one word
	la $t0 RED		# $t0 holds the red colour code
	sw $t0 0($sp)		# push a word onto the stack
	jal full_health_bar	# call full_health_bar
	
	la $t0 score_tracker	# $t0 = score_tracker address
	sw $zero 0($t0)		# set score_keeper to zero

	li $v0, 32
	li $a0, 1000 		# wait 1000 milliseconds
	syscall
	
	j main

end_screen:		addi $sp $sp -4		# move stack pointer one word
			la $t0 BLACK		# $t0 holds the black colour code
			sw $t0 0($sp)		# push a word onto the stack
			jal ship_draw_func	# call ship_draw_func
		
			addi $sp $sp -4		# move stack pointer one word
			la $t0 BLACK		# $t0 holds the black colour code
			sw $t0 0($sp)		# push a word onto the stack
			jal object_draw_func	# call object_draw_func
			
			li $v0, 32
			li $a0, 1000 		# wait 1000 milliseconds
			syscall
			
			la $t5 health_bar	# $t5 = health_bar address
			li $t6 31		# $t6 = 31
			sw $t6 0($t5)		# y = 31
			addi $sp $sp -4		# move stack pointer one word
			la $t0 DARK_RED		# $t0 holds the black colour code
			sw $t0 0($sp)		# push a word onto the stack
			jal full_health_bar	# call full_health_bar
			
			li $v0, 32
			li $a0, 1000 		# wait 1000 milliseconds
			syscall
			
			la $t5 health_bar	# $t5 = health_bar address
			li $t6 31		# $t6 = 31
			sw $t6 0($t5)		# y = 31
			addi $sp $sp -4		# move stack pointer one word
			la $t0 BLACK		# $t0 holds the black colour code
			sw $t0 0($sp)		# push a word onto the stack
			jal full_health_bar	# call full_health_bar
			
			la $a2 GREEN		# $a2 = green
			jal game_over
			
			la $a2 LIGHT_BLUE	# $a2 = light blue
			jal score_bar
			
			la $a2 LIGHT_PURPLE	# $a2 = light purple
			jal score_text
			
			la $a2 YELLOW		# $a2 = yellow
			jal score
			
			j wait_until_reset
			
wait_until_reset:	li $t9 KEYBOARD_INPUT			# check if the user has typed
			lw $t8 0($t9)
			beq $t8 1 check_if_reset
			j wait_until_reset

check_if_reset:		lw $t7, 4($t9) 				# this assumes $t9 is set to 0xfff0000 from before
			beq $t7 p_IN_ASCII erase_ending_screen  # check what key user has inputted
			j wait_until_reset

erase_ending_screen:	la $a2 BLACK
			jal game_over
			jal score_bar
			jal score_text
			jal score
			
			j reset
			
			
### helper function ###
paint_xy:	add $t0 $zero $a0	# $t0 = x
		add $t1 $zero $a1	# $t1 = y
		add $t2 $zero $a2	# $t2 = colour
		
		la $t3 BASE_ADDRESS	# $t3 holds the base address
		sll $t1 $t1 5		# $t1 = y * 32
		add $t1 $t1 $t0		# $t1 = y * 32 + x
		sll $t1 $t1 2		# $t0 = (y * 32 + x) * 4
		add $t1 $t1 $t3		# $t0 = (y * 32 + x) * 4 + BASE_ADDRESS	
		
		sw $t2 0($t1)
		jr $ra	
	
game_over:		addi $sp $sp -4		# move stack pointer one word
			sw $ra 0($sp)		# store the ra before using another jal call

			# printing the G
			li $a1 5		# $a1 = 5
			li $a0 10		# $a0 = 12
			jal paint_xy
			li $a0 9		# $a0 = 9
			jal paint_xy
			li $a0 8		# $a0 = 8
			jal paint_xy
			li $a1 6		# $a1 = 6
			jal paint_xy
			li $a1 7		# $a1 = 7
			jal paint_xy
			li $a1 8		# $a1 = 8
			jal paint_xy
			li $a0 9		# $a0 = 9
			jal paint_xy
			li $a0 10		# $a0 = 10
			jal paint_xy
			li $a1 7		# $a1 = 7
			jal paint_xy
			
			# printing the A
			li $a0 13		
			li $a1 5		
			jal paint_xy
			li $a0 12		
			li $a1 6		
			jal paint_xy
			li $a0 14				
			jal paint_xy
			li $a0 12		
			li $a1 7		
			jal paint_xy
			li $a0 13				
			jal paint_xy
			li $a0 14				
			jal paint_xy
			li $a0 12		
			li $a1 8		
			jal paint_xy
			li $a0 14				
			jal paint_xy
			
			# printing the M
			li $a0 16		
			li $a1 5		
			jal paint_xy
			li $a0 18		
			jal paint_xy
			li $a0 16		
			li $a1 6		
			jal paint_xy
			li $a0 17				
			jal paint_xy
			li $a0 18		
			jal paint_xy
			li $a0 16		
			li $a1 7		
			jal paint_xy
			li $a0 18		
			jal paint_xy
			li $a0 16		
			li $a1 8		
			jal paint_xy
			li $a0 18				
			jal paint_xy
			
			# printing the E
			li $a0 20		
			li $a1 5		
			jal paint_xy
			li $a0 21		
			jal paint_xy
			li $a0 22		
			jal paint_xy
			li $a0 20		
			li $a1 6		
			jal paint_xy		
			li $a1 7		
			jal paint_xy
			li $a0 21		
			jal paint_xy
			li $a0 20		
			li $a1 8		
			jal paint_xy
			li $a0 21		
			jal paint_xy
			li $a0 22		
			jal paint_xy
			
			# printing the O
			li $a0 8		
			li $a1 11		
			jal paint_xy
			li $a1 12		
			jal paint_xy
			li $a1 13		
			jal paint_xy
			li $a1 14		
			jal paint_xy
			li $a0 9		
			li $a1 11		
			jal paint_xy
			li $a1 14		
			jal paint_xy
			li $a0 10		
			li $a1 11		
			jal paint_xy		
			li $a1 12		
			jal paint_xy
			li $a1 13		
			jal paint_xy
			li $a1 14		
			jal paint_xy
			
			# printing the V
			li $a0 12		
			li $a1 11		
			jal paint_xy
			li $a1 12		
			jal paint_xy
			li $a1 13		
			jal paint_xy
			li $a0 13		
			li $a1 14		
			jal paint_xy
			li $a0 14		
			li $a1 11		
			jal paint_xy
			li $a1 12		
			jal paint_xy
			li $a1 13		
			jal paint_xy
			
			# printing the E
			li $a0 16		
			li $a1 11		
			jal paint_xy
			li $a1 12		
			jal paint_xy
			li $a1 13		
			jal paint_xy
			li $a1 14		
			jal paint_xy
			li $a0 17		
			li $a1 11		
			jal paint_xy
			li $a1 13		
			jal paint_xy
			li $a1 14		
			jal paint_xy
			li $a0 18		
			li $a1 11		
			jal paint_xy
			li $a1 14		
			jal paint_xy
			
			# printing the R
			li $a0 20		
			li $a1 11		
			jal paint_xy
			li $a1 12		
			jal paint_xy
			li $a1 13		
			jal paint_xy
			li $a1 14		
			jal paint_xy
			li $a0 21		
			li $a1 11		
			jal paint_xy
			li $a1 13		
			jal paint_xy
			li $a0 22		
			li $a1 11		
			jal paint_xy
			li $a1 12		
			jal paint_xy
			li $a1 14		
			jal paint_xy
			
			lw $ra 0($sp)		# load the ra
			addi $sp $sp 4		# move stack pointer one word
			
			jr $ra
			
score_text:		addi $sp $sp -4		# move stack pointer one word
			sw $ra 0($sp)		# store the ra before using another jal call
			
			# printing the S
			li $a0 7		
			li $a1 19		
			jal paint_xy		
			li $a1 21		
			jal paint_xy
			li $a1 22		
			jal paint_xy
			li $a0 6		
			li $a1 19		
			jal paint_xy		
			li $a1 20		
			jal paint_xy		
			li $a1 22		
			jal paint_xy
			
			# printing the C
			li $a0 10		
			li $a1 19		
			jal paint_xy		
			li $a1 22		
			jal paint_xy
			li $a0 9		
			li $a1 19		
			jal paint_xy
			li $a1 20		
			jal paint_xy
			li $a1 21		
			jal paint_xy
			li $a1 22		
			jal paint_xy
			
			# printing the O
			li $a0 12		
			li $a1 19		
			jal paint_xy		
			li $a1 20		
			jal paint_xy		
			li $a1 21		
			jal paint_xy
			li $a1 22		
			jal paint_xy
			li $a0 13		
			li $a1 19		
			jal paint_xy		
			li $a1 22		
			jal paint_xy
			li $a0 14		
			li $a1 19		
			jal paint_xy
			li $a1 20		
			jal paint_xy
			li $a1 21		
			jal paint_xy
			li $a1 22		
			jal paint_xy
			
			# printing the R
			li $a0 16		
			li $a1 19		
			jal paint_xy
			li $a1 20		
			jal paint_xy
			li $a1 21		
			jal paint_xy
			li $a1 22		
			jal paint_xy
			li $a0 17		
			li $a1 19		
			jal paint_xy
			li $a1 21		
			jal paint_xy
			li $a0 18		
			li $a1 20		
			jal paint_xy		
			li $a1 22		
			jal paint_xy
			
			# printing the E
			li $a0 20		
			li $a1 19		
			jal paint_xy		
			li $a1 20		
			jal paint_xy
			li $a1 21		
			jal paint_xy
			li $a1 22		
			jal paint_xy
			li $a0 21		
			li $a1 19		
			jal paint_xy
			li $a1 21		
			jal paint_xy
			li $a1 22		
			jal paint_xy
			li $a0 22		
			li $a1 19		
			jal paint_xy		
			li $a1 22		
			jal paint_xy
			li $a0 24		
			li $a1 19		
			jal paint_xy		
			li $a1 22		
			jal paint_xy
			
			lw $ra 0($sp)		# load the ra
			addi $sp $sp 4		# move stack pointer one word
			
			jr $ra
			
score_bar:		addi $sp $sp -4		# move stack pointer one word
			sw $ra 0($sp)		# store the ra before using another jal call
			
			# printing the upper horizontal portion
			li $a0 12		
			li $a1 24		
			jal paint_xy
			li $a0 13		
			jal paint_xy
			li $a0 14		
			jal paint_xy
			li $a0 15		
			jal paint_xy
			li $a0 16		
			jal paint_xy
			li $a0 17		
			jal paint_xy
			li $a0 18		
			jal paint_xy
			li $a0 19		
			jal paint_xy
			
			# printing the lower horizontal portion
			li $a0 12		
			li $a1 26		
			jal paint_xy
			li $a0 13		
			jal paint_xy
			li $a0 14		
			jal paint_xy
			li $a0 15		
			jal paint_xy
			li $a0 16		
			jal paint_xy
			li $a0 17		
			jal paint_xy
			li $a0 18		
			jal paint_xy
			li $a0 19		
			jal paint_xy
			
			# printing the side parts
			li $a0 12		
			li $a1 25		
			jal paint_xy
			li $a0 19				
			jal paint_xy
			
			lw $ra 0($sp)		# load the ra
			addi $sp $sp 4		# move stack pointer one word
			jr $ra
			
score:			addi $sp $sp -4		# move stack pointer one word
			sw $ra 0($sp)		# store the ra before using another jal call

			la $t0 score_tracker	# $t0 = score_keeper address
			lw $t0 0($t0)		# $t0 = # of times obj2 has reset (raw score)	
			div $t0 $t0 10		# interger division of $t0 by 10
			
			li $t1 1
			beq $t0 $t1 score1	# $t0 == 1
			li $t1 2
			beq $t0 $t1 score2	# $t0 == 2
			li $t1 3
			beq $t0 $t1 score3	# $t0 == 3
			li $t1 4
			beq $t0 $t1 score4	# $t0 == 4
			li $t1 5
			beq $t0 $t1 score5	# $t0 == 5
			li $t1 6
			bge $t0 $t1 max_score	# $t0 >= 6
			lw $ra 0($sp)		# load the ra
			addi $sp $sp 4		# move stack pointer one word
			jr $ra
			
score1:			li $a0 13
			li $a1 25
			jal paint_xy
			
			lw $ra 0($sp)		# load the ra
			addi $sp $sp 4		# move stack pointer one word
			jr $ra
			
score2:			li $a0 13
			li $a1 25
			jal paint_xy
			li $a0 14
			jal paint_xy
			
			lw $ra 0($sp)		# load the ra
			addi $sp $sp 4		# move stack pointer one word
			jr $ra
			
score3:			li $a0 13
			li $a1 25
			jal paint_xy
			li $a0 14
			jal paint_xy
			li $a0 15
			jal paint_xy
			
			lw $ra 0($sp)		# load the ra
			addi $sp $sp 4		# move stack pointer one word
			jr $ra
			
score4:			li $a0 13
			li $a1 25
			jal paint_xy
			li $a0 14
			jal paint_xy
			li $a0 15
			jal paint_xy
			li $a0 16
			jal paint_xy
			
			lw $ra 0($sp)		# load the ra
			addi $sp $sp 4		# move stack pointer one word
			jr $ra

score5:			li $a0 13
			li $a1 25
			jal paint_xy
			li $a0 14
			jal paint_xy
			li $a0 15
			jal paint_xy
			li $a0 16
			jal paint_xy
			li $a0 17
			jal paint_xy
			
			lw $ra 0($sp)		# load the ra
			addi $sp $sp 4		# move stack pointer one word
			jr $ra

max_score:		li $a0 13
			li $a1 25
			jal paint_xy
			li $a0 14
			jal paint_xy
			li $a0 15
			jal paint_xy
			li $a0 16
			jal paint_xy
			li $a0 17
			jal paint_xy
			li $a0 18
			jal paint_xy
			
			lw $ra 0($sp)		# load the ra
			addi $sp $sp 4		# move stack pointer one word
			jr $ra	
