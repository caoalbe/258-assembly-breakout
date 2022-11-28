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
    .word 31    # x-pos
    .word 57    # y-pos
    .word 1     # velocity-x
    .word -1    # velocity-y
    
PADDLE:
    .word 20    # x-pos
    .word 60    # y-pos
    .word 24    # width
    
BLOCKS:         # each block uses 4 words (x, y, broken, colour)
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
    
    

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
    # 2b. Update locations (paddle, ball)
    # 3. Draw the screen
    # 4. Sleep

    #5. Go back to 1
    
    
    # todo: sleep every cycle
    # jal draw_ball
    # jal update_ball
    
    b game_loop
    
    
    
    
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

        # draw_horizontal(x-pos, y-pos, 3, colour)
        lw $a0 0($s4)    # x-pos
        lw $a1 4($s4)    # y-pos
        li $a2 4         # 3
        lw $a3 8($s4) # colour
        jal draw_horizontal
        
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
    la $s3 COLOURS
    lw $s3 16($s3)   # 0xffffff
    
    
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
update_ball:
    # prologue
    addi $sp $sp -4
    sw $ra 0($sp)    # save return address into stack
    
    # body
    la $t0 BALL
    lw $t2 0($t0)    # x-pos
    lw $t3 4($t0)    # y-pos
    lw $t4 8($t0)    # x-speed
    lw $t5 12($t0)   # y-speed
    add $t2 $t2 $t4
    add $t3 $t3 $t5  
    
    sw $t2 0($t0)
    sw $t3 4($t0) 
    
    # todo: check collisions here
    
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
    
    la $t2 COLOURS
    lw $t2 16($t2)    #0xffffff
    
    # draw the four pixels
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
