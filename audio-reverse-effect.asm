.data
    in_fileName: .space 100      # Space for input filename
    out_fileName: .space 100     # Space for output filename

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

# get file size
    li $v0, 5
    syscall 
    move $s0, $v0       # file size (in bytes) in $s0

# Allocate memory for file size, for now just a sample size
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
    move $t0, $v0                # store file descriptor in $s3

read_file:
    # Read from input file
    li $v0, 14                   # syscall to read from file
    move $a0, $t0                # file descriptor
    move $a1, $s1                # buffer to store file content
    move $a2, $s0                # number of bytes to read
    syscall


     close_file:
    li $v0, 16
    move $a0, $t0
    syscall

    jal do_the_reverse

    j exit

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

exit:
    li $v0, 10                   # syscall to exit
    syscall

##########################
# $s0 - file size
# $s1 - input buffer memory
# $s2 - 
# $s3 - output file descriptor
##########################

do_the_reverse:
    move $t0, $s1     # in buffer memory address
    #li $t2, 44          # track first 44 to be written as is
    #la $t1, out_fileName    # out path address

open_for_writing:
    li $v0, 13
    la $a0, out_fileName
    li $a1, 577             # write only mode or create the file
    li $a2, 644                  # file permissions 0644 (read/write)
    syscall
    move $s3, $v0                # store output file descriptor

# # write the first 44 bytes unchanged
#     li $v0, 15
#     move $a0, $s3
#     move $a1, $s1              # buffer with the data
#     li $a2, 44                  # write the first 44 bytes
#     syscall

reverse_:
    add $t0, $t0, $s0           # address of input buffer + size---- move to the end
    sub $t0, $t0, 1             # minize 1 to point to last byte

    addi $t1, $s1, 44           # starting point, after header
    sub $t2, $s0, 44            # calc num of bytes to reverse

reverse_loop:
    blez $t2, done_reverse

    lb $t5, 0($t0)              # load the last byte at any moment
    sb $t5, 0($t1)              # store the last byte at front (rewriting the input file)
    addi $t0, $t0, -1           # move to load the next byte from end
    addi $t1, $t1, 1           # increment to store at the next location
    addi $t2, $t2, -1           # decrement tracker/counter to know when done reversing
    j reverse_loop

done_reverse:               # Write the reversed data to the output file
    li $v0, 15
    move $a0, $s3
    #addi $a1, $s1, 44       # point to reverse data after the header
    move $a1, $s1           # everthing to the new file
    #sub $a2, $s0, 44        # write remaining bytes -- the reversed
    move $a2, $s0           # bytes to write are same as read from input file (size of input file)

     jr $ra                 # return to main program

.data
    err_msg: .asciiz "Error opening file\n"

