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
.eqv LEFT_WALL_X 0
.eqv RIGHT_WALL_X 62
.eqv TOP_WALL_Y 7
.eqv BLOCK_DATA_SIZE 24

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

SCORE:
    .word 0        # bricks broken
    
BALL:
    .word 31       # x-pos
    .word 57       # y-pos
    .word 1        # velocity-x
    .word -1       # velocity-y
    .word 0xffffff # colour
    
PADDLE:
    .word 20       # x-pos
    .word 60       # y-pos
    .word 24       # width
    .word 0xffffff # colour
    
PADDLE2:
    .word 5       # x-pos
    .word 55       # y-pos
    .word 24       # width
    .word 0xffffff # colour
    
BLOCKS:            # each block uses 6 words (x, y, colour, isActive, health, isBreakable)
    .word 0:132    # 6 * BLOCKS_COUNT
    


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
    
    la $a1 PADDLE
    jal draw_paddle
    la $a1 PADDLE2
    jal draw_paddle
    
    jal initialize_blocks_memory
    
    # manually set brick at index 32 to unbreakable
    li $t0 0xdcddde
    la $t1 BLOCKS
    addi $t1 $t1 720 
    sw $zero 20($t1)
    sw $t0 8($t1)
    
    # manually set brick at index 29 to 2 health
    li $t0 2
    la $t1 BLOCKS
    addi $t1 $t1 696
    sw $t0 16($t1)
    
    jal draw_blocks
    
    

game_loop:
    # 1a. Check if key has been pressed
    lw $s0, ADDR_KBRD                   # $s0 = base address for keyboard
    lw $t8, 0($s0)                      # Load first word from keyboard
    bgt $t8, 1, keyboard_input_end      # If first word is not 1, key is not pressed
    blt $t8, 1, keyboard_input_end
    
    # 1b. Check which key has been pressed
    lw $a0, 4($s0)                   # Load second word from keyboard
    la $a1 PADDLE
    beq $a0, 0x61, respond_to_AD     # Check if the key a was pressed
    beq $a0, 0x41, respond_to_AD     # Check if the key A was pressed
    beq $a0, 0x64, respond_to_AD     # Check if the key d was pressed
    beq $a0, 0x44, respond_to_AD     # Check if the key D was pressed
    la $a1 PADDLE2
    beq $a0, 0x6A, respond_to_AD     # Check if the key j was pressed
    beq $a0, 0x4A, respond_to_AD     # Check if the key J was pressed
    beq $a0, 0x6C, respond_to_AD     # Check if the key l was pressed
    beq $a0, 0x4C, respond_to_AD     # Check if the key L was pressed
    
    beq $a0, 0x71, quit_game         # Check if the key q was pressed
    beq $a0, 0x51, quit_game         # Check if the key Q was pressed
    beq $a0, 0x70, pause_game        # Check if the key p was pressed
    beq $a0, 0x50, pause_game        # Check if the key P was pressed
    
    keyboard_input_end:
    
    # 2a. Check for collisions
    la $s6 BALL
    lw $s1 0($s6)  # x-pos
    lw $s2 4($s6)  # y-pos
    lw $s3 8($s6)  # x-speed
    lw $s4 12($s6)  # y-speed
    
    # todo: turn these checks into other functions
    # 
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
    
    # check_paddle_bounce #  <--------- FACTOR THIS OUT
    la $t0 PADDLE
    lw $t1 0($t0) # paddle left edge
    lw $t2 4($t0) # paddle y-pos
    addi $t2 $t2 -2
    lw $t3 8($t0) # paddle right edge
    add $t3 $t3 $t1
    blt $s2 $t2 end_check_paddle_bounce # correct height
    ble $s1 $t1 end_check_paddle_bounce # left boundary
    bgt $s1 $t3 end_check_paddle_bounce # right boundary
    check_paddle_bounce:
        # $s4 = +1, then set it to -1
        # $s4 = -1, then set it it +1
        srl $s4 $s4 1
        sll $s4 $s4 1
        not $s4 $s4
        sw $s4 12($s6)
    
    end_check_paddle_bounce:
    
    # check_paddle_bounce2
    la $t0 PADDLE2
    lw $t1 0($t0) # paddle left edge
    lw $t2 4($t0) # paddle y-pos
    addi $t2 $t2 -2
    lw $t3 8($t0) # paddle right edge
    add $t3 $t3 $t1
    blt $s2 $t2 end_check_paddle_bounce2 # correct height
    ble $s1 $t1 end_check_paddle_bounce2 # left boundary
    bgt $s1 $t3 end_check_paddle_bounce2 # right boundary
    check_paddle_bounce2:
        # $s4 = +1, then set it to -1
        # $s4 = -1, then set it it +1
        srl $s4 $s4 1
        sll $s4 $s4 1
        not $s4 $s4
        sw $s4 12($s6)
    
    end_check_paddle_bounce2:
    
    # check if game over
    beq $s2 63 quit_game
    
    # checks if ball hits a brick
    jal check_block_break
    
    
    
    # 2b. Update locations (paddle, ball)    
    jal update_ball
    
    # 3. Draw the screen
    la $a1 PADDLE
    jal draw_paddle
    la $a1 PADDLE2
    jal draw_paddle
    jal draw_ball
    # jal draw_blocks
    
    jal draw_score
    
    # 4. Sleep
    li $v0 32
    li $a0 33  # sleep for 33ms (1/30 of a second)
    syscall

    #5. Go back to 1
    b game_loop
    





# ---------------------------
# draw_digit
# a0: x-position
# a1: y-position
# a2: digit to draw
draw_digit:
    # prologue
    addi $sp $sp -16
    sw $ra 0($sp)
    sw $s0 4($sp)
    sw $s1 8($sp)
    sw $s2 12($sp)
    
    # save input arguments
    move $s0 $a0
    move $s1 $a1
    move $s2 $a2
    
    # draw top segment
    draw_digit_top_segment:
    beq $s2 1 draw_digit_top_right_segment
    beq $s2 4 draw_digit_top_right_segment
    beq $s2 6 draw_digit_top_right_segment
    move $a0 $s0
    move $a1 $s1
    li $a2 3
    li $a3 0xffffff 
    jal draw_horizontal
    
    # draw top-right segment
    draw_digit_top_right_segment:
    beq $s2 5 draw_digit_bottom_right_segment
    beq $s2 6 draw_digit_bottom_right_segment
    move $a0 $s0
    addi $a0 $a0 2
    move $a1 $s1
    li $a2 3
    li $a3 0xffffff 
    jal draw_vertical
    
    # draw bottom-right segment
    draw_digit_bottom_right_segment:
    beq $s2 2 draw_digit_bottom_segment
    move $a0 $s0
    addi $a0 $a0 2
    move $a1 $s1
    addi $a1 $a1 2
    li $a2 3
    li $a3 0xffffff 
    jal draw_vertical
    
    # draw bottom segment
    draw_digit_bottom_segment:
    beq $s2 1 draw_digit_bottom_left_segment
    beq $s2 4 draw_digit_bottom_left_segment
    beq $s2 7 draw_digit_bottom_left_segment
    move $a0 $s0
    move $a1 $s1
    addi $a1 $a1 4
    li $a2 3
    li $a3 0xffffff 
    jal draw_horizontal
    
    # draw bottom-left segment
    draw_digit_bottom_left_segment:
    beq $s2 1 draw_digit_top_left_segment
    beq $s2 3 draw_digit_top_left_segment
    beq $s2 4 draw_digit_top_left_segment
    beq $s2 5 draw_digit_top_left_segment
    beq $s2 7 draw_digit_top_left_segment
    beq $s2 9 draw_digit_top_left_segment
    move $a0 $s0
    move $a1 $s1
    addi $a1 $a1 2
    li $a2 3
    li $a3 0xffffff 
    jal draw_vertical
    
    # draw top-left segment
    draw_digit_top_left_segment:
    beq $s2 1 draw_digit_middle_segment
    beq $s2 2 draw_digit_middle_segment
    beq $s2 3 draw_digit_middle_segment
    beq $s2 7 draw_digit_middle_segment
    move $a0 $s0
    move $a1 $s1
    li $a2 3
    li $a3 0xffffff 
    jal draw_vertical
    
     # draw middle segment
    draw_digit_middle_segment:
    beq $s2 0 draw_digit_epilogue
    beq $s2 1 draw_digit_epilogue
    beq $s2 7 draw_digit_epilogue
    move $a0 $s0
    move $a1 $s1
    addi $a1 $a1 2
    li $a2 3
    li $a3 0xffffff 
    jal draw_horizontal
    
    # epilogue
    draw_digit_epilogue:
    lw $s2 12($sp)
    lw $s1 8($sp)
    lw $s0 4($sp)
    lw $ra 0($sp)
    addi $sp $sp 16
    jr $ra

# ---------------------------
# draw_score
draw_score:
    # prologue
    addi $sp $sp -12
    sw $ra 0($sp)
    sw $s0 4($sp)
    sw $s1 8($sp)
    
    # body
    # store each digit
    la $t0 SCORE
    lw $t0 0($t0)
    li $t1 10
    div $t0 $t1
    mfhi $s0    # ones digit
    mflo $s1    # tens digit
    
    # draw digits
    li $a0 2
    li $a1 1
    move $a2 $s1
    jal draw_digit
    
    li $a0 6
    li $a1 1
    move $a2 $s0
    jal draw_digit
    
    
    # epilogue
    draw_points_epilogue:
    lw $s1 8($sp)
    lw $s0 4($sp)
    lw $ra 0($sp)
    addi $sp $sp 12
    jr $ra




# ---------------------------
# check_block_break
# checks collision with blocks AND mutates state of ball if necessary
check_block_break:
    # prologue
    addi $sp $sp -36
    sw $ra 0($sp)
    sw $s0 4($sp)
    sw $s1 8($sp)
    sw $s2 12($sp)
    sw $s3 16($sp)
    sw $s4 20($sp)
    sw $s5 24($sp)
    sw $s6 28($sp)
    sw $s7 32($sp)
    
    # body
    la $t0 BALL
    lw $s0 0($t0)  # ball x-pos
    lw $s1 4($t0)  # ball y-pos
    lw $s2 8($t0)  # ball x-speed
    lw $s3 12($t0) # ball y-speed
    
    # iterate through each block
    li $s7 0       # i = 0
    la $t1 BLOCKS 
    check_block_break_loop:
        beq $s7 BLOCKS_COUNT check_block_break_epilogue # every brick has been checked
        lw $s4 0($t1)     # block x-pos
        addi $s4 $s4 -1   # x-target for ball
        lw $s5 4($t1)     # block y-pos
        addi $s5 $s5 1    # y-target for ball
        lw $s6 12($t1)    # block isActive
        beq $s6 $zero check_block_break_loop_end # block is inactive
        bgt $s1 $s5 check_block_break_loop_end   # ball is too down from brick
        
        blt $s0 $s4 check_block_break_loop_end   # ball is too far left
        addi $s4 $s4 4
        bgt $s0 $s4 check_block_break_loop_end   # ball is too far right
        
        # ball collides with brick
        lw $t3 20($t1)  
        beq $zero $t3 check_block_break_bounce_paddle # branch if block is not breakble
        
        # does brick have health
        li $t3 0xffff00 
        sw $t3 8($t1)    # set brick colour to yellow
        lw $t3 16($t1)
        addi $t3 $t3 -1
        sw $t3 16($t1)  # reduce health of brick by 1
        bgt $t3 $zero check_block_break_bounce_paddle # branch if block still has health 
        
        
        # brick is broken
        sw $zero 12($t1)   # set broken block to inactive
        sw $zero 8($t1)    # set broken block to black
        la $t7 SCORE
        lw $t6 0($t7)
        addi $t6 $t6 1
        sw $t6 0($t7)       # increment score
        
        jal undraw_score
        jal draw_score
        
        check_block_break_bounce_paddle:
        jal draw_blocks
        # ball bounces off brick
        li $s3 1
        la $t0 BALL
        sw $s3 12($t0)
        # j check_block_break_epilogue
        
    check_block_break_loop_end:
        addi $s7 $s7 1    
        addi $t1 $t1 BLOCK_DATA_SIZE
        j check_block_break_loop
    
    # epilogue
    check_block_break_epilogue:
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
# respond_to_AD
# moves paddle left and right
# $a0: character pressed
# $a1: address of paddle
respond_to_AD:
    # prologue
    addi $sp $sp -8
    sw $ra 0($sp)
    sw $s0 4($sp)
    
    # body
    move $t0 $a1
    move $s0 $a0
    
    # undraw-paddle
    li $t1 0x000000
    sw $t1 12($t0)  # sets paddle to black
    # move $a1 $a1
    jal draw_paddle # draw black paddle
    li $t1 0xffffff
    sw $t1 12($t0)  # sets paddle to white
    
    # move paddle left or right
    lw $t1 0($t0)  # loads x-pos
    beq $s0, 0x61, respond_to_A     # Check if the key a was pressed
    beq $s0, 0x41, respond_to_A     # Check if the key A was pressed
    beq $s0, 0x6A, respond_to_A     # Check if the key j was pressed
    beq $s0, 0x4A, respond_to_A     # Check if the key J was pressed
    # right arrow must have been pressed
    
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
    la $s4 BLOCKS       # each block is 6 words
    
    li $s5 0     # i = 0
    li $s6 BLOCKS_COUNT    # target = BLOCKS_COUNT
    draw_blocks_loop:
        slt $t0 $s5 $s6     # $s7 = i < target (1 or 0)
        beq $zero $t0 draw_blocks_epilogue
        # loop body
        lw $t1 12($s4)   # isActive
        # beq $t1 $zero draw_blocks_loop_end # skip draw_horizontal if block is not active

        # draw_horizontal(x-pos, y-pos, 3, colour)
        lw $a0 0($s4)    # x-pos
        lw $a1 4($s4)    # y-pos
        li $a2 4         # 3
        lw $a3 8($s4)    # colour
        jal draw_horizontal
        
        draw_blocks_loop_end:
        addi $s5 $s5 1    # i++
        addi $s4 $s4 BLOCK_DATA_SIZE   # next address
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
# s0: x-pos
# s1: y-pos
# s2: colour value
# s3: isActive
# s4: health
# s5: isBreakable
# s6: 
# s7:
# t0: i
# t1: BLOCKS_COUNT         = 33
# t2: BLOCK memory address
# t3: BLOCKS_PER_ROW       = 11
# t4: dummy immediate
initialize_blocks_memory:
    # prologue
    addi $sp $sp -28
    sw $ra 0($sp)
    sw $s0 4($sp)
    sw $s1 8($sp)
    sw $s2 12($sp)
    sw $s3 16($sp)
    sw $s4 20($sp)
    sw $s5 24($sp)
    
    # body
    li $s0 4                # x = 4
    li $s1 TOP_WALL_Y       # y = 4
    addi $s1 $s1 4
    la $s2 COLOURS
    lw $s2 0($s2)           # red
    li $s3 1                # active = true
    li $s4 1                # health = 1
    li $s5 1                # isBreakable = 1
              
    li $t0 0                # i = 0
    li $t5 0                # rowIndex = 0
    li $t1 BLOCKS_COUNT     # target = 33 blocks
    la $t2 BLOCKS           # BLOCKS[i]
    li $t3 BLOCKS_PER_ROW   # each row has 11 blocks
    initialize_blocks_memory_loop:
        slt $t4 $t0 $t1     # $t4 = i < target (1 or 0)
        beq $t5 3 intialize_blocks_memory_epilogue
        
        # loop body
        sw $s0 0($t2)       # x-pos
        sw $s1 4($t2)       # y-pos
        sw $s2 8($t2)       # colour
        sw $s3 12($t2)      # isActive
        sw $s4 16($t2)      # health
        sw $s5 20($t2)      # isBreakable
                
        addi $s0 $s0 5      # x += 5
        addi $t0 $t0 1      # i++
        addi $t2 $t2 BLOCK_DATA_SIZE     # $t2 moves to next block address
        
        # check next row of bricks
        # div $t0 $t3    # div is too slow
        # mfhi $t4     # t4 = i % 11
        # blt $zero $t4 initialize_blocks_memory_loop  # go to loop top if: 0 < i % 11
        blt $t0 $t3 initialize_blocks_memory_loop # go to loop top if: i < 11
            # mflo $t4 # t4 = i / 11
            li $t0 0       # i = 0
            addi $t5 $t5 1 # rowIndex++
            
            li $s0 4       # x = 4
            addi $s1 $s1 2 # y += 2
            
            la $s2 COLOURS   
            add $s2 $s2 $t5
            add $s2 $s2 $t5
            add $s2 $s2 $t5
            add $s2 $s2 $t5
            lw $s2 0($s2)    # s2 = next colour
            
            # go to loop top if: lo is odd
            # go to loop top if: rowIndex is odd
            andi $t4 $t5 1 # $t4 = $t4 mod 2
            beq $t4 $zero initialize_blocks_memory_loop
                li $s0 6 # x = 6
        j initialize_blocks_memory_loop
        
    # epilogue
    intialize_blocks_memory_epilogue:
    lw $s5 24($sp)
    lw $s4 20($sp)
    lw $s3 16($sp)
    lw $s2 12($sp)
    lw $s1 8($sp)
    lw $s0 4($sp)
    lw $ra 0($sp)
    addi $sp $sp 28
    jr $ra
    
# ---------------------------
# draw_paddle
# $a1: address of paddle
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
    move $t1 $a1 
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
    li $a0 LEFT_WALL_X
    li $a1 TOP_WALL_Y
    li $a2 64
    subi $a2 $a2 TOP_WALL_Y 
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_vertical
    li $a0 LEFT_WALL_X
    addi $a0 $a0 1
    li $a1 TOP_WALL_Y
    li $a2 64
    subi $a2 $a2 TOP_WALL_Y
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_vertical
    
    # right wall
    # draw_vertical(62, 0, 64, gray)
    # draw_vertical(63, 0, 64, gray)
    li $a0 RIGHT_WALL_X
    li $a1 TOP_WALL_Y
    li $a2 64
    subi $a2 $a2 TOP_WALL_Y
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_vertical
    li $a0 RIGHT_WALL_X
    addi $a0 $a0 1
    li $a1 TOP_WALL_Y
    li $a2 64
    subi $a2 $a2 TOP_WALL_Y
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_vertical
    
    
    # top wall
    # draw_horizontal(0, 0, 64, gray)
    # draw_horizontal(0, 1, 64, gray)
    li $a0 LEFT_WALL_X
    li $a1 TOP_WALL_Y
    li $a2 RIGHT_WALL_X
    subi $a2 $a2 LEFT_WALL_X
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_horizontal
    li $a0 LEFT_WALL_X
    li $a1 TOP_WALL_Y
    addi $a1 $a1 1
    li $a2 RIGHT_WALL_X
    subi $a2 $a2 LEFT_WALL_X
    la $a3 COLOURS
    lw $a3 20($a3)
    jal draw_horizontal
    
    # epilogue
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra
    
# ---------------------------
# undraw_score
# erases score on screen
undraw_score:
    # prologue
    addi $sp $sp -4
    sw $ra 0($sp)
    
    # body
    li $a0 2
    li $a1 1
    li $a2 7
    li $a3 0x000000
    jal draw_horizontal
    li $a0 2
    li $a1 2
    li $a2 7
    li $a3 0x000000
    jal draw_horizontal
    li $a0 2
    li $a1 3
    li $a2 7
    li $a3 0x000000
    jal draw_horizontal
    li $a0 2
    li $a1 4
    li $a2 7
    li $a3 0x000000
    jal draw_horizontal
    li $a0 2
    li $a1 5
    li $a2 7
    li $a3 0x000000
    jal draw_horizontal
    
    # epilogue
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra

# ---------------------------
# pause_game
# pauses game
pause_game:
    lw $t0, ADDR_KBRD                    # $t0 = base address for keyboard
    lw $t8, 0($t0)                       # Load first word from keyboard
    beq $t8, 1, unpause_input            # If first word 1, key is pressed
    j pause_game
    unpause_input:
    lw $a0, 4($t0)                       # Load second word from keyboard
    beq $a0, 0x70, keyboard_input_end    # Unpause game if p pressed
    beq $a0, 0x50, keyboard_input_end    # Unpause game if P pressed
    beq $a0, 0x71, quit_game             # Quit game if q pressed
    beq $a0, 0x51, quit_game             # Quit game if Q pressed
    j pause_game

# ---------------------------
# quit_game
# terminates game gracefully
quit_game:
    li $v0 10
    syscall
