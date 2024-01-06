.data
numrow: .asciiz  " 123456789\n"
space:  .asciiz " "
bar:    .asciiz "|"
divider: .asciiz "+--+--+--+--+--+--+\n"
topPtr: .asciiz "v\n"
botPtr: .asciiz "^\n"
userSymbol: .asciiz "X "
cpuSymbol: .asciiz "O "
newline:  .asciiz "\n"

.text

# make functions global
.globl printBoard printStatus

printBoard:
    # $a0: base addr
    la $t8, ($a0)

    # print top border
    la $a0, divider
    li $v0, 4
    syscall

    # 6x6 array
    li $a1, 6
    li $a2, 6
    li $t0, 0 #row counter

printRow:
    # Check if all rows are printed
    bge $t0, $a1, exitPrint # Exit loop if row counter >= number of rows

    # separate each space with bar
    li $v0, 4
    la $a0, bar
    syscall

    # Set $t1 as the column counter
    li $t1, 0 # Initialize column counter to 0

printCol:
    # Check if all columns are printed for the current row
    bge $t1, $a2, nextRow # Exit column loop if column counter >= number of columns

    # Calculate offset = (row counter * num_columns + column counter) * element_size
    mul $t3, $t0, 6     # Multiply row counter by number of columns
    add $t3, $t3, $t1 # Add column counter
    mul $t3, $t3, 4   # Multiply by element size (each element is 4 bytes)

    # Calculate address of the current element in the array
    add $t4, $t8, $t3 # $t4 = base address + offset

    # Load the value from the calculated address
    lw $t9, 0($t4)     # Load the value at address $t4 into $a0

    beq $t9, -1, userPrint
    beq $t9, -2, cpuPrint

    # if value loaded >= 10, skip the space adding
    bge $t9, 10, bigger10

    # if int one wide, add space for formatting
    la $a0, space
    li $v0, 4
    syscall
    
    # Print the value
    j bigger10
    
userPrint:
    # if board value -1, print user ASCII
    li $v0, 4
    la $a0, userSymbol
    syscall

    j afterPrint

cpuPrint:
    # if board value -2, print CPU ASCII
    li $v0, 4
    la $a0, cpuSymbol
    syscall

    j afterPrint

#printing two wide int or after adding space
bigger10:
    lw $a0, 0($t4)
    li $v0, 1         # syscall code for printing integer
    syscall

afterPrint:
    # Print a space for better readability
    li $v0, 4         # syscall code for printing string
    la $a0, bar     # Load address of space character
    syscall

    # Increment column counter
    addi $t1, $t1, 1  # Increment column counter
    j printCol  # Continue printing columns for the current row

nextRow:
    # Print a newline to move to the next row
    li $v0, 4         # syscall code for printing string
    la $a0, newline   # Load address of newline character
    syscall

    # print row divider
    la $a0, divider
    syscall

    # Increment row counter
    addi $t0, $t0, 1  # Increment row counter
    j printRow  # Continue printing rows until all rows are printed

exitPrint:
    jr $ra
    

# display pointers
printStatus:
    # store globals top and bottom to registers
    lw $t1, top
    lw $t2, bot

# create proper spacing for top pointer
loop1:
    # break loop if all spaces present
    ble $t1, 0, endLoop1
    
    # print space
    li $v0, 4
    la $a0, space
    syscall

    # decrement $t1
    subi $t1, $t1, 1

    j loop1

endLoop1:
    # print symbol for top pointer
    li $v0, 4
    la $a0, topPtr
    syscall

    # print integers 1-9
    li $v0, 4
    la $a0, numrow
    syscall

# create proper spacing for bottom pointer
loop2:
    # break loop if all spaces present
    ble $t2, 0, exitStatus

    # print space
    li $v0, 4
    la $a0, space
    syscall

    # decrement $t2
    subi $t2, $t2, 1
    j loop2

exitStatus:
    # print symbol for bottom pointer
    li $v0, 4
    la $a0, botPtr
    syscall
    
    jr $ra
