.global _start

.equ PIXEL_BUFFER, 0xC8000000 // Pixel buffer base address
.equ CHAR_BUFFER, 0xC9000000 // Chracter buffer base address

_start:
        bl      draw_test_screen
end:
        b       end

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
    MOV A1, #0 // Instantiate col index
    MOV A3, #0 // Colour value set to 0 to clear buffer

    for_each_col_in_pixelbuff:
        MOV A2, #0 // Instantiate row index
        CMP A1, #320
        BEQ VGA_clear_pixelbuff_ASM_end // Break from inner loop when we have iterated through all cols 0-319

    for_each_row_in_pixelbuff:
        CMP A1, #240
        BEQ for_each_row_in_pixelbuff_end // Break from outer loop when we have iterated through all rows 0-239
        BL VGA_draw_point_ASM // Branch to subroutine to clear buffer at current (x,y) coordinate
        ADD A2, A2, #1 // Increment row index
        B for_each_row_in_pixelbuff

    for_each_row_in_pixelbuff_end:
        ADD A1, A1, #1 // Increment col index
        B for_each_col_in_pixelbuff

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
        MOV A1, #0 // Instantiate row index
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


draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2

.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4

.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0

.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11 // R2 contains red bits, r7 contains blue bits
        lsl     r3, r4, #5 // Shift green bits
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3 // Colour value
        mov     r1, r4 // Move y-coordinate into R1 (argument for subroutine)
        mov     r0, r6 // Move x-coordinate into R0 (argument for subroutine)
        bl      VGA_draw_point_ASM
        add     r4, r4, #1 // Increment y-coordinate
        add     r5, r5, #32 // Loop counter
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7

.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}

.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071