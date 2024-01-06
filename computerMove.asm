.data
CPUThink: .asciiz "CPU Thinking"
period: .asciiz "."
doubleNewline: .asciiz "\n\n"

.text

# make functions global
.globl moveCPU

moveCPU:
    # push return address to stack
    addiu $sp, $sp, -4
    sw $ra, ($sp)

jumpCPU:
    # generate computer move
    jal idealMove
    
    # validate computer move
    addi $a0, $v1, 0 # pointer selection
    addi $a1, $v0, 0 # integer selection
    li $a2, -2 # owner (-2 = CPU)
    jal validateMove
    
    # if move invalid, regenerate move
    beq $v0, 0, jumpCPU
    
    # display CPU loading bar for visual appeal 
    j CPUWait

afterWait:
    # retrieve return address from stack
    lw $ra, ($sp)
    addiu $sp, $sp, 4

    jr $ra
    

# macro for program stall; increases readability
.macro sleep (%ms)
li $v0, 32
li $a0, %ms
syscall
.end_macro

CPUWait:
    # output CPU thinking string
    li $v0, 4
    la $a0, CPUThink
    syscall
    # output loading dot
    li $v0, 4
    la $a0, period
    syscall

    # wait 0.75 seconds
    sleep(750)

    # output loading dot
    li $v0, 4
    la $a0, period
    syscall

    # wait 0.5 seconds
    sleep(500)

    # output loading dot
    li $v0, 4
    la $a0, period
    syscall

    # wait 0.5 seconds
    sleep(500)

    # output newlines for spacing
    li $v0, 4
    la $a0, doubleNewline
    syscall

    j afterWait


# generate computer move   
idealMove:    
    
    # generate random int for top or bottom pointer
    li $v0, 42
    li $a0, 5
    li $a1, 2
    syscall
    
    # shift result from 0-1 to 1-2
    addi $a0, $a0, 1
    
    # store result
    la $v1, ($a0)
    
    # generate random integer selection
    li $v0, 42
    li $a0, 5
    li $a1, 8
    syscall
    
    # shift result from 0-8 to 1-9
    addi $a0, $a0, 1
    
    # store result
    la $v0, ($a0)
    
    jr $ra

