.data
    in_fileName: .space 100
    out_fileName: .space 100

.text
main:
# Get input file name
    li $v0, 8
    la $a0, in_fileName
    syscall

    li $s0, 0       #track - if == 0 then la == input file but if == 1 then output file
    jal remove_newline

# GEt output file name
    li $v0, 8
    la $a0, out_fileName
    syscall

    jal remove_newline

# get file size
    li $v0, 5
    syscall
    move $s0, $v0           # keep copy of file size in $s0

    j exit

remove_newline:
    beqz $s0, load_input_address
    bgtz $s0, load_output_address

find_newline:
    lb $a0, 0($t0)      

    beqz $a0, done_rmv_newline
    beq $s0, 0x0A rmv_it        # if newLine found, remove it

    add $t0, $t0, 1             # increment address pointer to next byte

    j find_newline              # recursion

rmv_it:
    sb $zero, 0($t0)
    jr $ra      # go back to find newline, where will branch back to main program

done_rmv_newline:
    jr $ra  # exit finding newline, back to main program

load_input_address:
    la $t0, in_fileName
    jr $ra  #back to remove new line
load_output_address:
    la $t0, out_fileName
    jr $ra  #back to remove new line
exit:
    li $v0, 10
    syscall