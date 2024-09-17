.data
    in_fileName: .space 100         
    out_fileName: .space 100      
    err_msg: .asciiz "Error opening file\n" 

.text
main:
    # Get input file name
    li $v0, 8                  
    la $a0, in_fileName           # input file name destination
    li $a1, 100                   # maximum number of characters
    syscall

    # Remove newline from input file name
    la $a0, in_fileName           
    jal remove_newline

    # Get output file name
    li $v0, 8                   
    la $a0, out_fileName          
    li $a1, 100                   
    syscall

    # Remove newline from output file name
    la $a0, out_fileName        
    jal remove_newline

    # Get file size
    li $v0, 5                    
    syscall 
    move $s0, $v0                # file size copied to $s0

    # Allocate memory for input buffer (heap 1)
    li $v0, 9                   
    move $a0, $s0                # allocate space for file size
    syscall
    move $s1, $v0                # store the address of allocated memory in $s1

    # Allocate memory for output buffer
    li $v0, 9                   
    move $a0, $s0                
    syscall
    move $s7, $v0                # store the address of allocated memory in $s7

open_file:
    # Open input file
    li $v0, 13                 
    la $a0, in_fileName          
    li $a1, 0                    # read-only mode
    li $a2, 0                    # default flags
    syscall

    # Check if file opened successfully
    bltz $v0, file_error          
    move $t0, $v0                # store file descriptor

read_file:
    # Read from input file
    li $v0, 14      
    move $a0, $t0                # file descriptor
    move $a1, $s1                # buffer (heap 1) to store file content
    move $a2, $s0                # number of bytes to read
    syscall

    # Close input file after reading
close_file:
    li $v0, 16
    move $a0, $t0
    syscall

    # Reverse audio data
    jal do_the_reverse

    # Open output file for writing
    li $v0, 13
    la $a0, out_fileName
    li $a1, 0x41                 # write-only mode, create file if doesn't exist
    li $a2, 0x1ff                # file permissions (0644)
    syscall
    move $s3, $v0                # store output file descriptor

    # Write reversed data to output file
    li $v0, 15
    move $a0, $s3
    move $a1, $s7                # buffer with reversed data
    move $a2, $s0                # write the full buffer
    syscall

    # Close output file
    li $v0, 16
    move $a0, $s3
    syscall

    # Exit
exit:
    li $v0, 10                   # syscall to exit
    syscall

file_error:
    # Handle file open error
    li $v0, 4                    # syscall to print string
    la $a0, err_msg              # error message
    syscall
    j exit

remove_newline:
    # Remove newline character from a string (input or output file)
    la $t0, 0($a0)               # load the string address (passed in $a0)

find_newline:
    lb $t1, 0($t0)               # load byte from the string
    beqz $t1, done_rmv_newline    # if null terminator found, end
    beq $t1, 0x0A, rmv_it         # if newline character (0x0A), remove it

    addi $t0, $t0, 1             # move to next character
    j find_newline

rmv_it:
    sb $zero, 0($t0)             # replace newline with null terminator
    j done_rmv_newline

done_rmv_newline:
    jr $ra                       # return to main program

do_the_reverse:
    move $t0, $s1                # heap1 staert
    move $t1, $s7                # output buffer address (heap2)

    li $a0, 44                   # header bytes
copy_header:
    beqz $a0, done_copy_header
    lb $t2, 0($t0)               
    sb $t2, 0($t1)               
    addi $t0, $t0, 1             # move to next byte in heap 1
    addi $t1, $t1, 1             # move to next byte in heap 2
    sub $a0, $a0, 1              # decrement count
    j copy_header

done_copy_header:
    # reverse the audio data
    sub $s5, $s0, 44             # data to reverse -- tracker
    add $t0, $s1, $s0            # point @end of heap 1
    sub $t0, $t0, 2              # point to 2nd last byte

reverse_loop:
    blez $s5, done_reverse       

    lh $t2, 0($t0)            
    sh $t2, 0($t1)               # store sample in output
    sub $s5, $s5, 2              # decrement count
    sub $t0, $t0, 2              # move down in heap1
    addi $t1, $t1, 2             # move up in heap 2
    j reverse_loop

done_reverse:
    jr $ra                       # return to main program
