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

.data
##############################################################################
# Immutable Data
COLOURS:
    .word 0xff0000    # red
    .word 0x00ff00    # green
    .word 0x0000ff    # blue
    
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

##############################################################################
# Code
##############################################################################
.text
.globl main

    # Run the Brick Breaker game.
main:
    # Initialize the game

    # Draw the board
    
    # draw_horizontal(0, 3, 64, 0x00ff00)
    li $a0 0
    li $a1 0
    li $a2 64
    la $a3 COLOURS
    lw $a3 4($a3)
    jal draw_vertical
    


game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
    # 2b. Update locations (paddle, ball)
    # 3. Draw the screen
    # 4. Sleep

    #5. Go back to 1
    b game_loop
    
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
    jal find_address    # places address of (x, y) into $v0
    addi $t1 $v0 0    

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