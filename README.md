# 258-assembly-breakout

preserved registers:
$s0 -> $s7
$ra
$sp
stack above the stack pointer

nonpreserved registers
$t0 -> $t9
$a0 -> $a3
$v0 -> $v1
stack below the stack pointer

functions
check_block_break: () -> void
respond_to_AD: (pressed) -> void
draw_blocks: () -> void
initialize_blocks_memory: () -> void
draw_paddle: () -> void
update_ball: () -> void
draw_ball: () -> void
todo: dont draw_vertical or draw_horizontal outside of canvas
draw_vertical: (x, y, height, colour) -> void  
draw_horizontal: (x, y, width, colour) -> void  
find_address: (x, y) -> address
draw_board: draws walls
quit_game: terminates game gracefully

todo:
fix ball squeezing through paddle bug
fix brick collision from side and from top
draw_paddle: () -> void
update_ball: () -> void
draw_ball: () -> void
should depend on memory address

features to implement (3 easy + 2 hard)
~~easy 5: pause game~~
~~ easy 7: unbreakable bricks~~
~~hard 1: track players score~~
~~easy 8: second paddle~~
~~hard 3: multiple hit bricks (colour for each health)~~
