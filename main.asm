.data
top: .word 0 # contains integer value of top pointer
bot: .word 0 # contains integer value of bottom pointer

board: # board contains values 1-81, if player claimed -> -1, if cpu claimed -> -2
	.word 1 2 3 4 5 6
	.word 7 8 9 10 12 14
	.word 15 16 18 20 21 24
	.word 25 27 28 30 32 35
	.word 36 40 42 45 48 49
	.word 54 56 63 64 72 81
	
.text

# make main and pointers globally accessible
.globl main top bot


# setup game
main:

    #hold board in permanent register
    la $s0, board

    # generate random starting int for bot pointer
    li $v0, 42
    li $a0, 0
    li $a1, 8
    syscall

    # shift value from 0-8 to 1-9 
    addi $a0, $a0, 1

    # store value in bot
    sw $a0, bot

    # print board
    la $a0, board
    jal printBoard
    
    # print status
    jal printStatus


# core game loop
mainLoop:
    # check that remaining moves contains possible move
    jal checkPossible
    
    # player turn
    jal moveUser
    
    # display board
    la $a0, board
    jal printBoard
    
    # display pointer status
    jal printStatus
    
    # check again since player moved
    jal checkPossible
    
    # CPU turn
    jal moveCPU
    
    # display board
    la $a0, board
    jal printBoard
    
    #display pointer status
    jal printStatus
    
    j mainLoop
    

