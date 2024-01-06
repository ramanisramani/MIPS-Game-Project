.data
winStr: .asciiz "\nYou win!\n"
lossStr: .asciiz "\nYou lose!\n"
noMoves: .asciiz "\nNo more moves possible, draw!\n"
.text

#make functions global
.globl checkPossible validateMove

checkPossible:
    #check that there are possible moves to be made to avoid soft locking
    li $t0, 0 #set row counter to 0
rows:
    bge $t0, 6, nonePossible
    li $t1, 0 #set col counter to 0
cols:
    bge $t1, 6, nextRow
    mul $t3, $t0, 6     # Multiply row counter by number of columns
    add $t3, $t3, $t1 # Add column counter
    mul $t3, $t3, 4   # Multiply by element size (each element is 4 bytes)

    # Calculate address of the current element in the array
    add $t4, $s0, $t3 # $t4 = base address + offset
    lw $t2, ($t4)
    ble $t2, 0, nextCol #if value is negative (claimed) go to next col iteration
calcMod:
    # $t2 contains value at space
    la $t4, ($t2) #copy value over to $t4 as well since checking two values
    #check top first
    lw $t3, top
    div $t2, $t3 #divide
    mfhi $t2 #get remainder
    beq $t2, 0, possible #if remainder is 0, meaning top is a factor of value, branch
    
    #check bot, same logic as check top
    lw $t3, bot
    div $t4, $t3
    mfhi $t2
    beq $t2, 0, possible
    
nextCol:
    addi $t1, $t1, 1
    j cols
    
nextRow:
    addi $t0, $t0, 1
    j rows
    
nonePossible:
    # print draw message and exit
    li $v0, 4
    la $a0, noMoves
    syscall
    
    # exit
    li $v0, 10
    syscall
    
possible:
    jr $ra


validateMove:
    # args:
    # $a0: ptr selection
    # $a1: int selection
    # $a2: owner
    
    # push return address onto stack
    addiu $sp, $sp, -4
    sw $ra, ($sp)
    
    # store owner in register t6
    la $t6, ($a2)
    
    # check if int input in range
    blt $a1, 1, returnFalse
    bgt $a1, 9, returnFalse
    
    
    
    # check if char valid
    beq $a0, 2, moveBot
    beq $a0, 1, moveTop
    
    
    # if invalid return false
    j returnFalse
  
    
moveBot:
    # check if selection currently selected
    lw $t0, bot
    beq $a1, $t0, returnFalse
    
    # calculate product of top and bottom pointers
    lw $t1, top
    mul $t2, $t1, $a1
    
    # check board for product of top and new bot
    la $a2, ($t2)
    la $a3, ($t6)
    jal checkBoard #return true or false
    
    beq $v0, 0, returnFalse # return false if checkBoard false
    
    # update bot
    sw $a1, bot
    
    # check for win
    addi $a0, $t6, 0
    addi $a1, $t0, 0
    addi $a2, $t1, 0
    jal checkWin
    
    # return true, retrieve return address and restore stack
    li $v0, 1
    lw $ra, ($sp)
    addiu $sp, $sp, 4
    jr $ra
    
moveTop:
    #check if selection currently selected    
    lw $t0, top
    beq $a1, $t0, returnFalse
    
    # calculate product of top and bottom pointers
    lw $t1, bot
    mul $t2, $t1, $a1
    
    # check board for product of bot and new top
    la $a2, ($t2)
    la $a3, ($t6)
    jal checkBoard #return true or false as $v0
    
    beq $v0, 0, returnFalse # return false if checkBoard false
    
    # update top
    sw $a1, top
    
    addi $a0, $t6, 0
    addi $a1, $t0, 0
    addi $a2, $t1, 0
    jal checkWin
    
    # return true, retrieve return address and restore stack
    li $v0, 1
    lw $ra, ($sp)
    addiu $sp, $sp, 4
    jr $ra
       
returnFalse:
    # return false, retrieve return address and restore stack
    li $v0, 0
    lw $ra, ($sp)
    addiu $sp, $sp, 4
    jr $ra
 
  
   
     
     
checkBoard:
    # args:
    # a2: value to find
    # a3: owner

    # v0: return 1 if found, 0 if not

    li $t0, 0 # row counter

iterateRow:
    # Check if all rows are printed
    bge $t0, 6, exitCheck # Exit loop if row counter >= number of rows
    
    # Set $t1 as the column counter
    li $t1, 0 # Initialize column counter to 0

iterateCol:
    bge $t1, 6, iteratenextRow # Exit column loop if column counter >= number of columns

    # Calculate offset = (row counter * num_columns + column counter) * element_size
    mul $t3, $t0, 6     # Multiply row counter by number of columns
    add $t3, $t3, $t1 # Add column counter
    mul $t3, $t3, 4   # Multiply by element size (each element is 4 bytes)

    # Calculate address of the current element in the array
    add $t4, $s0, $t3 # $t4 = base address + offset

    # Load the value from the calculated address
    lw $t5, 0($t4)     # Load the value at address $t4 into $t5
    beq $t5, $a2, found # If value is equal to search value, branch
    
    # Increment column counter
    addi $t1, $t1, 1
    j iterateCol

iteratenextRow:
    # Increment row counter
    addi $t0, $t0, 1  # Increment row counter
    j iterateRow

found:
    # update board value to ASCII for owner of space
    sw $a3, 0($t4)    
    
    # return true
    li $v0, 1
    jr $ra

exitCheck:
    # return false
    li $v0, 0
    jr $ra
    
    
checkWin:
    # args:
    # $a0: owner
    # $a1: moveRow
    # $a2: moveCol
    # $s0: board base address

    la $t0, 0($a1) #row counter
    li $t1, 0 # Initialize column counter to 0
    li $t6, 0 # Initialize found to 0
iterateRowWin:
    bge $t1, 6, colWin # Exit loop if column counter >= number of columns

    # Calculate offset = (row counter * num_columns + column counter) * element_size
    mul $t3, $t0, 6     # Multiply row counter by number of columns
    add $t3, $t3, $t1 # Add column counter
    mul $t3, $t3, 4   # Multiply by element size (each element is 4 bytes)

    # Calculate address of the current element in the array
    add $t4, $s0, $t3 # $t4 = base address + offset

    # Load the value from the calculated address
    lw $t5, 0($t4)
    beq $t5, $a0, numInARowRow
    li $t6, 0 # Reset found to 0
    addi $t1, $t1, 1  # Increment column counter
    j iterateRowWin 
    
numInARowRow:
    # If 4 spaces in a row belong to the player or the CPU, branch to win
    add $t6, $t6, 1
    beq $t6, 4, win
    addi $t1, $t1, 1  # Increment column counter
    j iterateRowWin
    
colWin:
    li $t0, 0 # Initialize row counter to 0
    li $t6, 0 # Initialize found to 0
    la $t1, 0($a2)    
iterateColWin:       
    bge $t0, 6, diagWinUp # Exit loop if row counter >= number of rows

    # Calculate offset = (row counter * num_columns + column counter) * element_size
    mul $t3, $t0, 6     # Multiply row counter by number of columns
    add $t3, $t3, $t1 # Add column counter
    mul $t3, $t3, 4   # Multiply by element size (each element is 4 bytes)

    # Calculate address of the current element in the array
    add $t4, $t8, $t3 # $t4 = base address + offset

    # Load the value from the calculated address
    lw $t5, 0($t4)
    beq $t5, $a0, numInARowCol
    li $t6, 0 # Reset found to 0
    addi $t0, $t0, 1  # Increment row counter
    j iterateColWin

numInARowCol:
    # If 4 spaces in a row belong to the player or the CPU, branch to win
    add $t6, $t6, 1
    beq $t6, 4, win
    addi $t0, $t0, 1  # Increment row counter
    j iterateColWin
           
diagWinUp:
    la $t0, 0($a1)  # Initialize row counter to row the move was made on
    li $t6, 0 # Initialize found to 0
    la $t1, 0($a2)
 shiftDiagUp:
    # Exit loop if reach edge of board
    beq $t0, 5, iterateDiagWinUp
    beq $t1, 0, iterateDiagWinUp 
    addi $t0, $t0, 1
    subi $t1, $t1, 1
    
    j shiftDiagUp 
iterateDiagWinUp:       
    beq $t0, $a0, diagWinDown  
    beq $t1, 6, diagWinDown

    # Calculate offset = (row counter * num_columns + column counter) * element_size
    mul $t3, $t0, 6     # Multiply row counter by number of columns
    add $t3, $t3, $t1 # Add column counter
    mul $t3, $t3, 4   # Multiply by element size (each element is 4 bytes)

    # Calculate address of the current element in the array
    add $t4, $t8, $t3 # $t4 = base address + offset

    # Load the value from the calculated address
    lw $t5, 0($t4)
    beq $t5, $a0, numInARowDiagUp
    li $t6, 0 # Reset found to 0
    # Increment row counter
    addi $t1, $t1, 1
    subi $t0, $t0, 1
    j iterateDiagWinUp

numInARowDiagUp:
    # If 4 spaces in a row belong to the player or the CPU, branch to win
    add $t6, $t6, 1
    beq $t6, 4, win
    addi $t1, $t1, 1
    subi $t0, $t0, 1  # Increment column counter
    j iterateDiagWinUp
    
diagWinDown:
    la $t0, 0($a1)  # Initialize row counter to 0
    li $t6, 0 # Initialize found to 0
    la $t1, 0($a2)
 shiftDiagDown:
    # Exit loop if reach edge of board
    beq $t0, 0, iterateDiagWinDown
    beq $t1, 0, iterateDiagWinDown
    subi $t0, $t0, 1
    subi $t1, $t1, 1
    
    j shiftDiagDown 
iterateDiagWinDown:       
    beq $t0, 6, noWin # Exit loop if row counter >= number of rows  
    beq $t1, 6, noWin # Exit loop if col counter >= number of cols  

    # Calculate offset = (row counter * num_columns + column counter) * element_size
    mul $t3, $t0, 6     # Multiply row counter by number of columns
    add $t3, $t3, $t1 # Add column counter
    mul $t3, $t3, 4   # Multiply by element size (each element is 4 bytes)

    # Calculate address of the current element in the array
    add $t4, $t8, $t3 # $t4 = base address + offset

    # Load the value from the calculated address
    lw $t5, 0($t4)
    beq $t5, $a0, numInARowDiagDown
    li $t6, 0 # Reset found to 0
    addi $t1, $t1, 1
    addi $t0, $t0, 1
    j iterateDiagWinDown

numInARowDiagDown:
    # If 4 spaces in a row belong to the player or the CPU, branch to win
    add $t6, $t6, 1
    beq $t6, 4, win
    addi $t1, $t1, 1
    addi $t0, $t0, 1
    j iterateDiagWinDown

noWin:
	jr $ra
 
                         
win:
    addiu $sp, $sp, -4
    sw $a0, ($sp)

    #final board print
    la $a0, ($s0)
    jal printBoard
    
    #final status print
    jal printStatus

    lw $a0, ($sp)
    addiu $sp, $sp, 4
    
    bne $a0, -1, loss

    la $a0, winStr
    li $v0, 4
    syscall
    
    j exit

loss:
    la $a0, lossStr
    li $v0, 4
    syscall

exit:
    li $v0, 10
    syscall
    
