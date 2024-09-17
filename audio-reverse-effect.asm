.data
    in_fileName: .space 100      # Space for input filename
    out_fileName: .space 100     # Space for output filename
    err_msg: .asciiz "Error opening file\n"   # Error message

.text
main:
    # Get input file name
    li $v0, 8                    # syscall to read string
    la $a0, in_fileName           # input file name destination
    li $a1, 100                   # maximum number of characters
    syscall

    # Remove newline from input file name
    jal remove_newline

    # Get output file name
    li $v0, 8                   
    la $a0, out_fileName          # output file name destination
    li $a1, 100                   # maximum number of characters
    syscall

    # Remove newline from output file name
    jal remove_newline

    # Get file size
    li $v0, 5
    syscall 
    move $s0, $v0       # file size (in bytes) in $s0

    # Allocate memory for file size
    li $v0, 9                   
    move $a0, $s0                
    syscall
    move $s1, $v0                # store the address of allocated memory in $s1

open_file:
    # Open input file
    li $v0, 13                 
    la $a0, in_fileName           # load address of input filename
    li $a1, 0                    # read-only mode
    li $a2, 0                    # default flags
    syscall

    # Check if file opened successfully
    bltz $v0, file_error          # if file descriptor < 0, there was an error
    move $t0, $v0                # store file descriptor

read_file:
    # Read from input file
    li $v0, 14                   # syscall to read from file
    move $a0, $t0                # file descriptor
    move $a1, $s1                # buffer to store file content
    move $a2, $s0                # number of bytes to read
    syscall

    # Close input file after reading
close_file:
    li $v0, 16
    move $a0, $t0
    syscall

    # Reverse audio data
    jal do_the_reverse

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
    la $t0, in_fileName           # load the filename address (modify for output later)

find_newline:
    lb $a0, 0($t0)               # load byte from filename

    beqz $a0, done_rmv_newline    # if null terminator found, end
    beq $a0, 0x0A, rmv_it         # if newline character (0x0A), remove it

    addi $t0, $t0, 1             # move to next character
    j find_newline

rmv_it:
    sb $zero, 0($t0)             # replace newline with null terminator
    j done_rmv_newline

done_rmv_newline:
    jr $ra                       # return to main program

##########################
# $s0 - file size
# $s1 - input buffer memory
# $s3 - output file descriptor
##########################

do_the_reverse:
    move $t0, $s1     # input buffer memory address (start)

    # Open output file for writing
open_for_writing:
    li $v0, 13
    la $a0, out_fileName
    li $a1, 577             # write only mode or create the file
    li $a2, 644             # file permissions 0644 (read/write)
    syscall
    move $s3, $v0           # store output file descriptor

    # Write the first 44 bytes unchanged (header)
write_header:
    li $v0, 15
    move $a0, $s3
    move $a1, $s1              # buffer with the data
    li $a2, 44                 # write the first 44 bytes (header)
    syscall

    # Reverse the audio data
reverse_:
    add $t0, $t0, $s0           # address of input buffer + size, move to the end
    sub $t0, $t0, 1             # point to the last byte

    addi $t1, $s1, 44           # starting point after header
    sub $t2, $s0, 44            # calculate the number of bytes to reverse

reverse_loop:
    blez $t2, done_reverse

    lb $t5, 0($t0)              # load the last byte
    sb $t5, 0($t1)              # store the byte in the reversed position
    addi $t0, $t0, -1           # move backwards in input buffer
    addi $t1, $t1, 1            # move forwards in output buffer
    addi $t2, $t2, -1           # decrement the reverse byte count
    j reverse_loop

# Write the reversed data after the header
done_reverse:               
    li $v0, 15
    move $a0, $s3
    addi $a1, $s1, 44        # point to reversed data after the header
    sub $a2, $s0, 44         # write the remaining reversed bytes (excluding the header)
    syscall

close_out_file:
    li $v0, 16
    move $a0, $s3
    syscall

    jr $ra                   # return to main program
