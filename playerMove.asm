.data
promptPtr: .asciiz "Enter '1' to move the top pointer or '2' to move the bottom pointer: "
promptInt: .asciiz "Enter integer selection 1 - 9: "
firstMovePrompt: .asciiz "Select an integer 1 - 9 to move the top pointer to: "
invalidStr: .asciiz "Invalid selection\n"

.text

# make functions global
.globl moveUser

moveUser:
    # push return address to stack
    addiu $sp, $sp, -4
    sw $ra, ($sp)

jumpLoc:
    # check if first move
    la $t7, top
    beq $t7, 0, firstMove

    # prompt user for pointer selection    
    la $a0, promptPtr
    li $v0, 4
    syscall
    
    # retrieve pointer selection
    li $v0, 5
    syscall
    la $t5, ($v0)

    # prompt user for integer selection
    la $a0, promptInt
    li $v0, 4
    syscall

    j getInt
    
firstMove:
    # pointer is top by default on first move
    li $t5, 1

    # prompt user for first move integer selection
    la $a0, firstMovePrompt
    li $v0, 4
    syscall

getInt:
    # retrieve integer selection
    li $v0, 5
    syscall
       
    # validate selected move
    la $a0, ($t5) # pointer selection
    la $a1, ($v0) # integer selection
    li $a2, -1 # owner (-1 = player)
    jal validateMove
    
    # if invalid, print invalid and restart loop
    beq $v0, 0, invalidMove
    
    # retrieve return address from stack
    lw $ra, ($sp)
    addiu $sp, $sp, 4

    jr $ra
    
invalidMove:
    # display to user invalid selection message
    la $a0, invalidStr
    li $v0, 4
    syscall
    
    j jumpLoc
