################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Albert Cao, 1006282764
# Student 2: 
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    512
# - Display height in pixels:   512
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################
.eqv BLOCKS_COUNT 33
.eqv BLOCKS_PER_ROW 11

.data
##############################################################################
# Immutable Data
COLOURS:
    .word 0xff0000    # red
    .word 0x00ff00    # green
    .word 0x0000ff    # blue
    .word 0x000000    # black
    .word 0xffffff    # white
    .word 0xdcddde    # gray
    
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################

BALL:
    .word 31       # x-pos
    .word 57       # y-pos
    .word 1       # velocity-x
    .word -1       # velocity-y
    .word 0xffffff # colour
    
PADDLE:
    .word 20       # x-pos
    .word 60       # y-pos
    .word 24       # width
    .word 0xffffff # colour
    
BLOCKS:         # each block uses 4 words (x, y, colour, isActive)
    .word 0:132  # 4 * BLOCKS_COUNT

##############################################################################
# Code
##############################################################################
.text
.globl main

    # Run the Brick Breaker game.
main:
    # Initialize the game

    # Draw the board
    jal draw_board
    
    jal draw_ball
    
    jal draw_paddle
    
    jal initialize_blocks_memory
    jal draw_blocks
    
    li $s7 0    # 0: game is pause, 1: game is active
    
    

game_loop:
    # 1a. Check if key has been pressed
    lw $s0, ADDR_KBRD                   # $s0 = base address for keyboard
    lw $t8, 0($s0)                      # Load first word from keyboard
    bgt $t8, 1, keyboard_input_end      # If first word is not 1, key is not pressed
    blt $t8, 1, keyboard_input_end
    
    # 1b. Check which key has been pressed
    lw $a0, 4($s0)                   # Load second word from keyboard
    beq $a0, 0x61, respond_to_AD     # Check if the key a was pressed
    beq $a0, 0x41, respond_to_AD     # Check if the key A was pressed
    beq $a0, 0x64, respond_to_AD     # Check if the key d was pressed
    beq $a0, 0x44, respond_to_AD     # Check if the key D was pressed
    beq $a0, 0x71, quit_game         # Check if the key q was pressed
    beq $a0, 0x51, quit_game         # Check if the key Q was pressed
    beq $a0, 0x20, pause_unpause     # Check if the key <space> was pressed
    pause_unpause:   # flips $s0 between 0 and 1
    addi $s7 $s7 1
    andi $s7 $s7 1
    # j keyboard_input_end
    
    keyboard_input_end:
    
    # 2a. Check for collisions
    la $s6 BALL
    lw $s1 0($s6)  # x-pos
    lw $s2 4($s6)  # y-pos
    lw $s3 8($s6)  # x-speed
    lw $s4 12($s6)  # y-speed
    
    
    # check_wall_bounce
    ble $s1 2 check_wall_bounce_reflect
    bge $s1 60 check_wall_bounce_reflect
    j end_check_wall_bounce
    check_wall_bounce_reflect:
    # $s1 <= 2 OR $s1 >= 61
        # $s3 = +1, then set it to -1
        # $s3 = -1, then set it to +1
        srl $s3 $s3 1
        sll $s3 $s3 1
        not $s3 $s3
        sw $s3 8($s6)
    end_check_wall_bounce:
    
    # check_top_wall_bounce
    ble $s2 2 check_top_wall_bounce
    j end_check_top_wall_bounce
    check_top_wall_bounce:
    # $s2 <= 2
        # $s4 = +1, then set it to -1
        # $s4 = -1, then set it it +1
        srl $s4 $s4 1
        sll $s4 $s4 1
        not $s4 $s4
        sw $s4 12($s6)
    end_check_top_wall_bounce:
    
    # check_paddle_bounce
    la $t0 PADDLE
    lw $t1 0($t0) # paddle x-pos
    lw $t2 4($t0) # paddle y-pos
    addi $t2 $t2 -2
    lw $t3 8($t0) # paddle width
    add $t3 $t3 $t1
    blt $s2 $t2 end_check_paddle_bounce # correct height
    # ble $s1 $t1 end_check_paddle_bounce # left boundary
    # bgt $s1 $t3 end_check_paddle_bounce # right boundary
    check_paddle_bounce:
        # $s4 = +1, then set it to -1
        # $s4 = -1, then set it it +1
        srl $s4 $s4 1
        sll $s4 $s4 1
        not $s4 $s4
        sw $s4 12($s6)
    
    end_check_paddle_bounce:
    
    
    # 2b. Update locations (paddle, ball)    
    jal update_ball
    
    # 3. Draw the screen
    jal draw_paddle
    
    jal draw_ball
    
    jal draw_blocks
    
    # 4. Sleep
    li $v0 32
    li $a0 33  # sleep for 33ms (1/30 of a second)
    syscall

    #5. Go back to 1
    b game_loop
    


# ---------------------------
# respond_to_AD
# moves paddle left and right
# $a0: character pressed
respond_to_AD:
    # prologue
    addi $sp $sp -8
    sw $ra 0($sp)
    sw $s0 4($sp)
    
    # body
    la $t0 PADDLE
    move $s0 $a0
    
    # undraw-paddle
    li $t1 0x000000
    sw $t1 12($t0)  # sets paddle to black
    jal draw_paddle # draw black paddle
    li $t1 0xffffff
    sw $t1 12($t0)  # sets paddle to white
    
    # move paddle left or right
    lw $t1 0($t0)  # loads x-pos
    beq $s0, 0x61, respond_to_A     # Check if the key a was pressed
    beq $s0, 0x41, respond_to_A     # Check if the key A was pressed
    # d or D must have been pressed
    
    respond_to_D:
    addi $t1 $t1 1
    
    # bound paddle to right wall
    ble $t1 38 respond_to_AD_epilogue
        li $t1 38
    j respond_to_AD_epilogue
    
    respond_to_A:
    addi $t1 $t1 -1
    # bound paddle to left wall
    bge $t1 2 respond_to_AD_epilogue
        li $t1 2
    j respond_to_AD_epilogue
    
    # epilogue
    respond_to_AD_epilogue:
    sw $t1 0($t0)
    
    lw $s0 4($sp)
    lw $ra 0($sp)
    addi $sp $sp 8
    jr $ra
    
# ---------------------------
# draw_blocks
draw_blocks:
# draws from memory
    # prologue
    addi $sp $sp -36
    sw $ra 0($sp)    # save return address into stack
    sw $s0 4($sp)
    sw $s1 8($sp)
    sw $s2 12($sp)
    sw $s3 16($sp)
    sw $s4 20($sp)
    sw $s5 24($sp)
    sw $s6 28($sp)
    sw $s7 32($sp)
    
    # body
    la $s4 BLOCKS       # each block is 4 words
    
    # todo: support multiple rows
    li $s5 0     # i = 0
    li $s6 BLOCKS_COUNT    # target = BLOCKS_COUNT
    draw_blocks_loop:
        slt $t0 $s5 $s6     # $s7 = i < target (1 or 0)
        beq $zero $t0 draw_blocks_epilogue
        # loop body
        lw $t1 12($s4)   # isActive
        beq $t1 $zero draw_blocks_loop_end # skip draw_horizontal if block is not active

        # draw_horizontal(x-pos, y-pos, 3, colour)
        lw $a0 0($s4)    # x-pos
        lw $a1 4($s4)    # y-pos
        li $a2 4         # 3
        lw $a3 8($s4)    # colour
        jal draw_horizontal
        
        draw_blocks_loop_end:
        addi $s5 $s5 1    # i++
        addi $s4 $s4 16   # next address
        j draw_blocks_loop
        
    # epilogue
    draw_blocks_epilogue:
    lw $s7 32($sp)
    lw $s6 28($sp)
    lw $s5 24($sp)
    lw $s4 20($sp)
    lw $s3 16($sp)
    lw $s2 12($sp)
    lw $s1 8($sp)
    lw $s0 4($sp)
    lw $ra 0($sp)
    addi $sp $sp 36
    jr $ra

# ---------------------------
# initialize_blocks
# sets memory values
# todo: refactor this code (specify meaning of each register)
initialize_blocks_memory:
    # prologue
    addi $sp $sp -32
    sw $ra 0($sp)    # save return address into stack
    sw $s0 4($sp)
    sw $s1 8($sp)
    sw $s2 12($sp)
    sw $s3 16($sp)
    sw $s4 20($sp)
    sw $s5 24($sp)
    sw $s7 28($sp)
    
    # body
    li $s0 4              # x = 4
    li $s1 4              # y = 4
    la $s7 COLOURS
    lw $s2 0($s7)         # red
    
    li $s3 1              # active = true
    la $s4 BLOCKS         # each block is 4 words
    li $s5 BLOCKS_PER_ROW # each row has 11 blocks
        
    # todo: support multiple rows
    li $t0 0    # i = 0
    li $t1 BLOCKS_COUNT    # target = 11 blocks
    li $t3 0    # row-index
    initialize_blocks_memory_loop:
        slt $t2 $t0 $t1     # $t2 = i < target (1 or 0)
        beq $zero $t2 intialize_blocks_memory_epilogue
        # loop body
        sw $s0 0($s4)
        sw $s1 4($s4)
        sw $s2 8($s4)
        sw $s3 12($s4)
        
        addi $s4 $s4 16   # $s4 moves to next block address
        addi $s0 $s0 5    # x = x + 5
        addi $t0 $t0 1    # i++
        
        # beq $t0 # check if i == 11 or 22
        blt $t0 $s5 initialize_blocks_memory_loop
            addi $s1 $s1 2 # y += 2
            addi $s5 $s5 BLOCKS_PER_ROW # move next target
            addi $t3 $t3 1 # incremement row-index
            
            addi $s7 $s7 4
            lw $s2 0($s7)         # next colour
            
            
            li $s0 4       # x = 4
            # if $t3 is even, add 2 to $s0
            andi $t4 $t3 1 # $t4 = $t3 mod 2
            beq $t4 $zero initialize_blocks_memory_loop
                addi $s0 $s0 2 # x = 6
        
        j initialize_blocks_memory_loop
        
    # epilogue
    intialize_blocks_memory_epilogue:
    lw $s6 28($sp)
    lw $s5 24($sp)
    lw $s4 20($sp)
    lw $s3 16($sp)
    lw $s2 12($sp)
    lw $s1 8($sp)
    lw $s0 4($sp)
    lw $ra 0($sp)
    addi $sp $sp 32
    jr $ra
    
# ---------------------------
# draw_paddle
# $s0: x-pos of left edge
# $s1: y-pos of left edge <-- is this constant??
# $s2: width of paddle
# $s3: colour of paddle
draw_paddle:
    # prologue
    addi $sp $sp -20
    sw $ra 0($sp)    # save return address into stack
    # save registers $s0 to $s3
    sw $s0 4($sp)
    sw $s1 8($sp)
    sw $s2 12($sp)
    sw $s3 16($sp)
    
    # body
    la $t1 PADDLE
    lw $s0 0($t1)    # x-pos
    lw $s1 4($t1)    # y-pos
    lw $s2 8($t1)    # width
    # la $s3 COLOURS (unused now)
    lw $s3 12($t1)   # colour
    
    
    # draw_horizontal(x, y, width, white)
    addi $a0 $s0 0
    addi $a1 $s1 0
    addi $a2 $s2 0
    addi $a3 $s3 0
    jal draw_horizontal
    
    # draw_horizontal(x+1, y+1, width-2, white)  <-- tapered paddle is prettier
    addi $a0 $s0 2
    addi $a1 $s1 1
    addi $a2 $s2 -4
    addi $a3 $s3 0
    jal draw_horizontal
    
    # epilogue
    lw $s3 16($sp)
    lw $s2 12($sp)
    lw $s1 8($sp)
    lw $s0 4($sp)
    lw $ra 0($sp)
    addi $sp $sp 20
    jr $ra


# ---------------------------
# update_ball()
# un-draw ball, add speed to location
update_ball:
    # prologue
    addi $sp $sp -4
    sw $ra 0($sp)    # save return address into stack
    
    # body
    la $t0 BALL
    
    # un-draw ball
    li $t7 0x000000
    sw $t7 16($t0)
    jal draw_ball
    li $t7 0xffffff
    sw $t7 16($t0)
    
    # change ball data
    lw $t2 0($t0)    # x-pos
    lw $t3 4($t0)    # y-pos
    lw $t4 8($t0)    # x-speed
    lw $t5 12($t0)   # y-speed
    add $t2 $t2 $t4
    add $t3 $t3 $t5  
    
    sw $t2 0($t0)
    sw $t3 4($t0) 
    
    # todo: check collisions here
    # hierarchy: 
    # side-wall: flip y-speed
    # top-wall: flip both x-speed and y-speed
    # block: flip x-speed and set y-speed = +1
    # paddle: depends on position
    
    # epilogue
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra


# ---------------------------
# draw_ball (if array of balls in future, should depend on an index)
# $t0: return address
# $t1: pixel address
# $t2: colour value
draw_ball:
    # prologue
    addi $sp $sp -4
    sw $ra 0($sp)    # save return address into stack
    
    # body
    la $a0 BALL
    lw $a1 4($a0)    # $a1 = y-pos
    lw $a0 0($a0)    # $a0 = x-pos
  
    jal find_address
    addi $t1 $v0 0    # places address of (x-pos, y-pos) into $t1
    
    
    la $a0 BALL
    lw $t2 16($a0)   # loads ball colour
    
    # draw the four pixels of the ball
    sw $t2 0($t1)
    sw $t2 4($t1)
    addi $t1 $t1 256
    sw $t2 0($t1)
    sw $t2 4($t1)
    
    # epilogue
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra
    

# should draw functions wrap around or stop???
# ---------------------------
# draw_vertical(x, y, height, colour)
    # x = $a0; 0 <= x <= 63
    # y = $a1; 0 <= y <= 63
    # height = $a2; 0 <= height + y <= 64
    # colour = $a3; colour = 0x????????
    # $t0: return address
    # $t1: memory location of pixel
    # $t3: i
    # $t4: i < height (boolean)
draw_vertical:
    # prologue
    addi $sp $sp -4
    sw $ra 0($sp)    # save return address into stack
    
    # body  
    jal find_address
    addi $t1 $v0 0    # places address of (x, y) into $t1

    addi $t3 $zero 0    # $t3 = i = 0
vertical_line_loop: 
    slt $t4, $t3, $a2    # $t4 = i < width (1 or 0)
    beq $t4 $0 end_vertical_line
        sw $a3 0($t1)
        addi $t1 $t1 256
        addi $t3 $t3 1
        b vertical_line_loop

    # epilogue
end_vertical_line:
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra


# ---------------------------
# draw_horizontal(x, y, width, colour)
    # x = $a0; 0 <= x <= 63
    # y = $a1; 0 <= y <= 63
    # width = $a2; 0 <= width + x <= 64
    # colour = $a3; colour = 0x????????
    # $t0: return address
    # $t1: memory location of pixel
    # $t3: i
    # $t4: i < width (boolean)
draw_horizontal:
    # prologue
    addi $sp $sp -4
    sw $ra 0($sp)    # save return address into stack
    
    # body  
    jal find_address    # places address of (x, y) into $v0
    addi $t1 $v0 0    

    addi $t3 $zero 0    # $t3 = i = 0
horizontal_line_loop: 
    slt $t4, $t3, $a2    # $t4 = i < width (1 or 0)
    beq $t4 $0 end_horizontal_line
        sw $a3 0($t1)
        addi $t1 $t1 4
        addi $t3 $t3 1
        b horizontal_line_loop

    # epilogue
end_horizontal_line:
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra


# ---------------------------
# find_address(x, y)
    # x = $a0; 0 <= x <= 32
    # y = $a1; 0 <= y <= 32
    # output = $v0
    # $t1: x-offset
    # $t2: y-offset
find_address:
    # prologue
    addi $sp $sp -4
    sw $ra 0($sp)
   
    # body
    lw $v0 ADDR_DSPL    # output = ADDR_DSPL
   
    addi $t1 $zero 4    # each pixel is 1 word (4 bytes)
    addi $t2 $zero 256   # each row has 64 pixels (256 bytes)
   
    mult $t1 $a0
    mflo $t1        # $t1 = x-offset
    mult $t2 $a1
    mflo $t2        # $t2 = y-offset
    
    add $v0 $v0 $t1    # output += x-offset
    add $v0 $v0 $t2    # output += y-offset
    
    # epilogue  
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra

# ---------------------------
# draw_board()
draw_board:
    # prologue
    addi $sp $sp -4
    sw $ra 0($sp)    # save return address into stack
    
    # body
    
    # left wall
    # draw_vertical(0, 0, 64, gray)
    # draw_vertical(1, 0, 64, gray)
    li $a0 0
    li $a1 0
    li $a2 64
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_vertical
    li $a0 1
    li $a1 0
    li $a2 64
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_vertical
    
    # right wall
    # draw_vertical(62, 0, 64, gray)
    # draw_vertical(63, 0, 64, gray)
    li $a0 62
    li $a1 0
    li $a2 64
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_vertical
    li $a0 63
    li $a1 0
    li $a2 64
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_vertical
    
    
    # top wall
    # draw_horizontal(0, 0, 64, gray)
    # draw_horizontal(0, 1, 64, gray)
    li $a0 0
    li $a1 0
    li $a2 64
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_horizontal
    li $a0 0
    li $a1 1
    li $a2 64
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_horizontal
    
    # epilogue
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra


# ---------------------------
# quit_game
# terminates game gracefully
quit_game:
    li $v0 10
    syscall
