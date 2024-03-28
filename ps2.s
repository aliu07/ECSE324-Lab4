.global _start

.equ PIXEL_BUFFER, 0xC8000000 // Pixel buffer base address
.equ CHAR_BUFFER, 0xC9000000 // Chracter buffer base address
.equ KBD_REGISTER, 0xFF200100 // PS/2 data register address

_start:
        bl      input_loop
end:
        b       end

@ TODO: copy VGA driver here.
/*---------- VGA DRIVERS ----------*/

// This subroutine draws a point on the screen at the specified (x, y) coordinates in the indicated color c. 
// The subroutine should check that the coordinates supplied are valid, i.e., x in [0, 319] and y in [0, 239]. 
// Hint: This subroutine should only access the pixel buffer.
// INPUT: A1 -> x-coordinate, A2 -> y-coordinate, A3 -> color half-word
VGA_draw_point_ASM:
    PUSH {V1-V2, LR}
    // INPUT VALIDATION
    CMP A1, #0
    BLT VGA_draw_point_ASM_end // Exit function if x < 0
    CMP A1, #320
    BGE VGA_draw_point_ASM_end // Exit function if x > 319
    CMP A2, #0
    BLT VGA_draw_point_ASM_end // Exit function if y < 0
    CMP A2, #239
    BGT VGA_draw_point_ASM_end // Exit function if y > 239
    // SUBROUTINE LOGIC
    LDR V1, =PIXEL_BUFFER // Load pixel buffer base address
    MOV V2, A2 // Instantiate offset value to y-coordinate
    LSL V2, #10 // Shift y-coordinate up 10 bits
    LSL A1, #1 // Shift x-coordinate up 1 bit temporarily
    ADD V2, V2, A1 // Add in x-coordinate
    ASR A1, #1 // Shift x-coordinate back down 1 bit to original value
    STRH A3, [V1, V2] // Store lower 16 bits in colour register A3 into base address + x-y offset
    
    VGA_draw_point_ASM_end:
        POP {V1-V2, PC}

// This subroutine clears (sets to 0) all the valid memory locations in the pixel buffer. It takes no arguments 
// and returns nothing. 
// Hint: You can implement this function by calling VGA_draw_point_ASM with a color value of zero for every valid 
// location on the screen.
VGA_clear_pixelbuff_ASM:
    PUSH {LR}
    MOV A2, #0 // Instantiate row index
    MOV A3, #0 // Colour value set to 0 to clear buffer

    for_each_row_in_pixelbuff:
        MOV A1, #0 // Instantiate col index
        CMP A2, #240
        BEQ VGA_clear_pixelbuff_ASM_end // Break from inner loop when we have iterated through all rows 0-219

    for_each_col_in_pixelbuff:
        CMP A1, #320
        BEQ for_each_row_in_pixelbuff_end // Break from outer loop when we have iterated through all cols 0-319
        BL VGA_draw_point_ASM // Branch to subroutine to clear buffer at current (x,y) coordinate
        ADD A1, A1, #1 // Increment col index
        B for_each_col_in_pixelbuff

    for_each_row_in_pixelbuff_end:
        ADD A2, A2, #1 // Increment row index
        B for_each_row_in_pixelbuff

    VGA_clear_pixelbuff_ASM_end:
        POP {PC}

// This subroutine writes the ASCII code c to the screen at (x, y). The subroutine should check that the 
// coordinates supplied are valid, i.e., x in [0, 79] and y in [0, 59]. 
// Hint: This subroutine should only access the character buffer.
// INPUT: A1 -> x-coordinate, A2 -> y-coordinate, A3 -> ASCII value of character
VGA_write_char_ASM:
    PUSH {V1-V2, LR}
    // INPUT VALIDATION
    CMP A1, #0
    BLT VGA_write_char_ASM_end // Exit function if x < 0
    CMP A1, #79
    BGT VGA_write_char_ASM_end // Exit function if x > 79
    CMP A2, #0
    BLT VGA_write_char_ASM_end // Exit function if y < 0
    CMP A2, #59
    BGT VGA_write_char_ASM_end // Exit function if y > 59
    // SUBROUTINE LOGIC
    LDR V1, =CHAR_BUFFER
    MOV V2, A2 // Instantiate offset value to y-coordinate
    LSL V2, #7 // Shift y-coordinate up 7 bits
    ADD V2, V2, A1 // Add in x-coordinate
    STRB A3, [V1, V2] // Store ASCII value into character buffer at base address + x-y offset

    VGA_write_char_ASM_end:
        POP {V1-V2, PC}

// This subroutine clears (sets to 0) all the valid memory locations in the character buffer. It takes no 
// arguments and returns nothing. 
// Hint: You can implement this function by calling VGA_write_char_ASM with a character value of zero for 
// every valid location on the screen.
VGA_clear_charbuff_ASM:
    PUSH {LR}
    MOV A2, #0 // Instantiate row index
    MOV A3, #0 // ASCII value set to 0 to clear buffer

    for_each_row_in_charbuff:
        MOV A1, #0 // Instantiate col index
        CMP A2, #60
        BEQ VGA_clear_pixelbuff_ASM_end // Break from inner loop when we have iterated through all rows 0-219

    for_each_col_in_charbuff:
        CMP A1, #80
        BEQ for_each_row_in_charbuff_end // Break from outer loop when we have iterated through all cols 0-319
        BL VGA_write_char_ASM // Branch to subroutine to clear buffer at current (x,y) coordinate
        ADD A1, A1, #1 // Increment col index
        B for_each_col_in_charbuff

    for_each_row_in_charbuff_end:
        ADD A2, A2, #1 // Increment row index
        B for_each_row_in_charbuff

    VGA_clear_charbuff_ASM_end:
        POP {PC}



@ TODO: insert PS/2 driver here.
/*---------- PS/2 DRIVERS ----------*/

// This subroutine checks the RVALID bit in the PS/2 Data register. If it is valid, then the data should be read, 
// stored at the address data, and the subroutine should return 1. If the RVALID bit is not set, then the subroutine 
// should return 0.
// OUTPUT: A1 -> RVALID bit
read_PS2_data_ASM:
    PUSH {V1-V2, LR}
    LDR V1, =KBD_REGISTER // Load address of data register
    LDR V2, [V1] // Load contents of data register into V2
    ASR V2, #15 // Shift right by 15 bits
    AND A1, V2, #0x1 // Return MSB read i.e. RVALID bit in A1
    POP {V1-V2, PC}

write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}
