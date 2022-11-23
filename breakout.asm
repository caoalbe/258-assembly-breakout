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
    la $t0 COLOURS
    lw $t0 0($t0)    # $t0 = 0xff0000 = red
    
    la $t1 ADDR_DSPL
    lw $t1 0($t1)    # $t1 = top-left pixel

    li $t2 64    # $t2 = width = 64
    
    li $t3 0    # $t3 = i = 0
    
horizontal_line_loop:  # todo: turn this into a function
    slt $t4, $t3, $t2    # $t4 = i < width (1 or 0)
    beq $t4 $0 end_horizontal_line
    
        sw $t0 0($t1)
        addi $t1 $t1 4
        addi $t3 $t3 1
        
        b horizontal_line_loop


end_horizontal_line:

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
    # 2b. Update locations (paddle, ball)
    # 3. Draw the screen
    # 4. Sleep

    #5. Go back to 1
    b game_loop
