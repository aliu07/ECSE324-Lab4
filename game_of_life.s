.section .vectors, "ax"
B _start            // reset vector
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0             // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector

/*--- Undefined instructions --------------------------------------*/
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ----------------------------------------*/
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads ------------------------------------------*/
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch -----------------------------------*/
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ---------------------------------------------------------*/
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR
/* NOTE: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the DE1-SoC Computer Manual
   on page 46 */
Pushbutton_check:
    CMP R5, #79 // ID of PS/2 keyboard
UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here
    BL PS2_ISR
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
SUBS PC, LR, #4
/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
    B SERVICE_FIQ


.global _start

.equ PIXEL_BUFFER, 0xC8000000 // Pixel buffer base address
.equ CHAR_BUFFER, 0xC9000000 // Chracter buffer base address
.equ KBD_REGISTER, 0xFF200100 // PS/2 data register address

GoLBoard:
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.byte 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 2
	.byte 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 3
	.byte 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 4
	.byte 0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0 // 5
	.byte 0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0 // 6
	.byte 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 7
	.byte 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 8
	.byte 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 9
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // a
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b

_start:
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR CPSR_c, R1           // change to IRQ mode
    LDR SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 on-chip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR CPSR, R1             // change to supervisor mode
    LDR SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL  CONFIG_GIC           // configure the ARM GIC
    // NOTE: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    // to enable interrupt for ARM A9 private timer, 
    // use ARM_TIM_config_ASM subroutine
    LDR R0, =0xFF200050      // pushbutton KEY base address
    MOV R1, #0xF             // set interrupt mask bits
    STR R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
    MOV R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR CPSR_c, R0

	// Clear buffer
	BL VGA_clear_pixelbuff_ASM
	// Colour
	MOV A1, #0xff
	LSL A1, #8
	ADD A1, A1, #0xff
    BL GoL_draw_grid_ASM
    // New colour
    MOV A1, #0xff
	// Initiate game board
    BL GoL_draw_board_ASM
	
IDLE:
	B IDLE


/*---------- GoL DRIVERS ----------*/

// This subroutine fills grid locations (x, y), 0 ≤ x < 16, 0 ≤ y < 12 with colour c if GoLBoard[y][x] == 1.
// INPUT: A1 -> Colour c
GoL_draw_board_ASM:
    PUSH {V1-V4, LR}
    MOV V1, #0 // Instantiate row index to 0
    LDR V3, =GoLBoard // Load base address of game board
    MOV A3, A1 // Move colour c argument into A3 for subroutine GoL_fill_gridxy_ASM
    
    for_each_row:
        CMP V1, #12 // Exit outer loop when row index = 12
        BEQ GoL_draw_board_ASM_end
        MOV V2, #0 // Instantiate column index to 0

    for_each_column:
        CMP V2, #16 // Exit inner loop when column index = 16
        BEQ for_each_row_end
        MOV A4, V1 // Move row index into A4 (A4 will hold offset value)
        LSL A4, #4 // Multiply by 16 to get proper row in memory for game board
        ADD A4, A4, V2 // Add column offset to get proper column
        LDRB V4, [V3, A4] // Load value of game board at (x, y)
        CMP V4, #1 // Check if value is 1
        MOVEQ A1, V2 // Move column index (x) into A1 if value is 1
        MOVEQ A2, V1 // Move row index (y) into A2 if value is 1
        BLEQ GoL_fill_gridxy_ASM // Fill grid cell at (x, y) if value is 1
        ADD V2, V2, #1 // Increment column index
        B for_each_column // Branch to next iteration

    for_each_row_end:
        ADD V1, V1, #1 // Increment x index
        B for_each_row // Branch to next iteration

    GoL_draw_board_ASM_end:
        POP {V1-V4, PC}

// This subroutine fills the area of grid location (x, y) with colour c.
// The grid is 16x12, hence 0 <= x < 16 and 0 <= y < 12
// INPUT: A1 -> x-coord, A2 -> y-coord, A3 -> colour c
GoL_fill_gridxy_ASM:
    PUSH {V1-V4, LR}
    // INPUT VALIDATION
    CMP A1, #0
    BLT GoL_fill_gridxy_ASM_end // Exit if x < 0
    CMP A1, #16
    BGE GoL_fill_gridxy_ASM_end // Exit if x >= 16
    CMP A2, #0
    BLT GoL_fill_gridxy_ASM_end // Exit if y < 0
    CMP A2, #12
    BGE GoL_fill_gridxy_ASM_end // Exit if y >= 12
    // SUBROUTINE LOGIC
    MOV V4, #20 // Move constant 20 into V4
    MOV V1, A1 // Move x to V1
    MUL V1, V1, V4 // Multiply x by 20 to get pixel x-coordinate (call it x1)
    CMP A1, #0 // Check if x = 0
    ADDNE V1, V1, #1 // Add 1 to x1 if x != 0
    MOV V2, A2 // Move y to V2
    MUL V2, V2, V4 // Multiply y by 20 to get pixel y-coordinate (call it y1)
    CMP A2, #0 // Check if y = 0
    ADDNE V2, V2, #1 // Add 1 to y1 if y != 0
    MOV V3, V1 // Duplicate x1 into V3
    ADD V3, V3, #19 // Compute x2
    MOV V4, V2 // Duplicate y1 into V4
    ADD V4, V4, #18 // Compute y2
    CMP A1, #0 // Special case when x = 0, we draw one colum of pixels more than usual
    ADDEQ V3, V3, #1
    CMP A2, #0 // Special case when y = 0, we draw one more row of pixels than usual
    ADDEQ V4, V4, #1
    MOV A1, V2 // Move y1 into A1
    LSL A1, #9 // Shift up
    ADD A1, A1, V1 // Add in x1
    LSL A1, #1 // Shift up for half-word memory alignment
    MOV A2, V4 // Move y2 into A2
    LSL A2, #9 // Shift up
    ADD A2, A2, V3 // Add in x2
    LSL A2, #1 // Shift up for half-word memory alignment
    BL VGA_draw_rect_ASM // Draw rectangle from (x, y)

    GoL_fill_gridxy_ASM_end:
        POP {V1-V4, PC}


// This subroutine draws a rectangle from pixel (x1, y1) to (x2, y2) in colour c.
// INPUTS: A1 -> (x1, y1), A2 -> (x2, y2), A3 -> colour c
// COORDINATE FORMAT: YYYYYYYY XXXXXXXXX 0 -> 9 bits for X, 8 bits for Y, 0 LSB for half-word memory access alignment
VGA_draw_rect_ASM:
    PUSH {V1-V4, LR}
    MOV V1, A1 // Move (x1, y1) into V1
    LSL V1, #22 // Shift up to clear y1
    LSR V1, #23 // Shift back down to have only x1
    MOV V2, A1 // Move (x1, y1) into V2
    LSR V2, #10 // Shift down to have only y1
    MOV V3, A2 // Move (x2, y2) into V3
    LSL V3, #22 // Shift up to clear y2
    LSR V3, #23 // Shift back down to have only x2
    MOV V4, A2 // Move (x2, y2) into V4
    LSR V4, #10 // Shift down to have only y2
    // MOVE SMALLEST X INTO V1 AND SMALLEST Y INTO V2
    CMP V1, V3 // Check x1 vs x2
    MOVGT A4, V1 // Case x1 > x2, store x1 in A4 temporarily
    MOVGT V1, V3 // Move x2 (smaller x-coordinate) into V1
    MOVGT V3, A4 // Move x1 (larger x-coordinate) into V3
    CMP V2, V4 // Check y1 vs y2
    MOVGT A4, V2 // Case y1 > y2, store y1 in A4 temporarily
    MOVGT V2, V4 // Move y2 (smaller y-coordinate) into V2
    MOVGT V4, A4 // Move y1 (large y-coordinate) into V4

    draw_rect_loop:
        MOV A1, V2 // Move y1 into A1
        LSL A1, #9 // Shift up
        ADD A1, A1, V1 // Add in x1
        LSL A1, #1 // Shift up for half-word memory alignment
        MOV A2, V4 // Move y2 into A2
        LSL A2, #9 // Shift up
        ADD A2, A2, V1 // Add in x1
        LSL A2, #1 // Shift up for half-word memory alignment
        BL VGA_draw_line_ASM // Draw line from (x1, y1) to (x1, y2)
        ADD V1, V1, #1 // Increment x1
        CMP V1, V3 // Check if x1 = x2
        BNE draw_rect_loop // Exit loop if x1 = x2

    POP {V1-V4, PC}

// This subroutine draws a 16x12 grid to the VGA display.
// INPUT: A1 -> colour c
GoL_draw_grid_ASM:
    PUSH {V1-V4, LR}
    MOV V1, #20 // Instantiate x1 to 20
    MOV V2, #0 // Instantiate y1 to 0
    MOV V3, #20 // Instantiate x2 to 20
    MOV V4, #239 // Instantiate y2 to 239
    MOV A3, A1 // Move argument colour c into A3 for VGA_draw_line_ASM subroutine

    draw_vertical_lines_loop:
        MOV A1, V1 // Add in x1 (we don't beed to move in y1 since it will always remain 0)
        LSL A1, #1 // Shift up for half-word memory alignment
        MOV A2, V4 // Move y2 into A2
        LSL A2, #9 // Shift up
        ADD A2, A2, V3 // Add in x2
        LSL A2, #1 // Shift up for half-word memory alignment
        BL VGA_draw_line_ASM // Draw line from (x1, y1) to (x2, y2)
        ADD V1, V1, #20 // Increment x1
        ADD V3, V3, #20 // Increent x2
        CMP V1, #320 // Check for end condition
        BNE draw_vertical_lines_loop
        // SETUP FOR DRAWING HORIZONTAL LINES
        MOV V1, #0 // Instantiate x1 to 0
        MOV V2, #20 // Instantiate y1 to 20
        MOV V3, #255
        ADD V3, V3, #64 // Instantiate x2 to 319
        MOV V4, #20 // Instantiate y2 to 20

    draw_horizontal_lines_loop:
        MOV A1, V2 // Move y1 into A1
        LSL A1, #10 // Shift up (x1 always 0, so don't need to add in x1)
        MOV A2, V4 // Move y2 into A2
        LSL A2, #9 // Shift up
        ADD A2, A2, V3 // Add in x2
        LSL A2, #1 // Shift up for half-word alighment
        BL VGA_draw_line_ASM // Draw line from (x1, y1) to (x2, y2)
        ADD V2, V2, #20 // Increment y1
        ADD V4, V4, #20 // Increment y2
        CMP V2, #240 // Check for end condition
        BNE draw_horizontal_lines_loop

    POP {V1-V4, PC}

// This subroutine draws a line from a (x1, y1) to (x2, y2) in a colour c.
// INPUT: A1 -> (x1, y1), A2 -> (x2, y2), A3 -> Colour value c (half-word)
// COORDINATE FORMAT: YYYYYYYY XXXXXXXXX 0 -> 9 bits for X, 8 bits for Y, 0 LSB for half-word memory access alignment
VGA_draw_line_ASM:
    PUSH {V1-V4, LR}
    MOV V1, A1 // Move (x1, y1) into V1
    LSL V1, #22 // Shift up to clear y1
    LSR V1, #23 // Shift back down to have only x1
    MOV V2, A1 // Move (x1, y1) into V2
    LSR V2, #10 // Shift down to have only y1
    MOV V3, A2 // Move (x2, y2) into V3
    LSL V3, #22 // Shift up to clear y2
    LSR V3, #23 // Shift back down to have only x2
    MOV V4, A2 // Move (x2, y2) into V4
    LSR V4, #10 // Shift down to have only y2
    // Case x1 = x2 -> Draw vertical line
    CMP V1, V3
    BEQ draw_vertical_line
    // Case y1 = y2 -> Draw horizontal line
    CMP V2, V4
    BEQ draw_horizontal_line
    B VGA_draw_line_ASM_end // If we did not match with any of the 2 cases, then simply exit function

    draw_vertical_line:
        CMP V2, V4 // Check which y-coordinate is greater
        MOVGE A2, V4 // Case y1 >= y2, we move y2 into A2
        MOVLT A2, V2 // Case y1 < y2, we move y1 into A2
        MOV A1, V1 // Move x1 into A1 (x1 = x2, so doesn't matter which one)
        MOVGE V1, V2 // Move upper bound y1 into V1 if we have y1 >= y2
        MOVLT V1, V4 // Move upper bound y2 into V1 if we have y1 < y2

    draw_vertical_line_loop:
        CMP A2, V1 // Check current y against upper bound
        BGT VGA_draw_line_ASM_end // If so, exit function
        BL VGA_draw_point_ASM // Draw point of colour c at current (x, y)
        ADD A2, A2, #1 // Increment y-coordinate
        B draw_vertical_line_loop

    draw_horizontal_line:
        CMP V1, V3 // Check which x-coordinate is greater
        MOVGE A1, V3 // Case x1 >= x2, we move x2 into A1
        MOVLT A1, V1 // Case x1 < x2, we move x1 into A1
        MOV A2, V2 // Move y1 into A2 (y1 = y2, so doesn't matter which one)
        MOVLT V1, V3 // Move upper bound x2 into V1 if we have x1 < x2 (for other case, x1 already in V1)

    draw_horizontal_line_loop:
        CMP A1, V1 // Check current x against upper bound
        BGT VGA_draw_line_ASM_end // If so, exit function
        BL VGA_draw_point_ASM // Draw point of colour c at current (x, y)
        ADD A1, A1, #1 // Increment x-coordinate
        B draw_horizontal_line_loop

    VGA_draw_line_ASM_end:
        POP {V1-V4, PC}

/*---------- VGA DRIVERS ----------*/

// This subroutine draws a point on the screen at the specified (x, y) coordinates in the indicated colour c. 
// The subroutine should check that the coordinates supplied are valid, i.e., x in [0, 319] and y in [0, 239]. 
// Hint: This subroutine should only access the pixel buffer.
// INPUT: A1 -> x-coordinate, A2 -> y-coordinate, A3 -> colour half-word
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
    LSR A1, #1 // Shift x-coordinate back down 1 bit to original value
    STRH A3, [V1, V2] // Store lower 16 bits in colour register A3 into base address + x-y offset
    
    VGA_draw_point_ASM_end:
        POP {V1-V2, PC}

// This subroutine clears (sets to 0) all the valid memory locations in the pixel buffer. It takes no arguments 
// and returns nothing. 
// Hint: You can implement this function by calling VGA_draw_point_ASM with a colour value of zero for every valid 
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





/*---------- PS/2 DRIVERS ----------*/

// This subroutine checks the RVALID bit in the PS/2 Data register. If it is valid, then the data should be read, 
// stored at the address data, and the subroutine should return 1. If the RVALID bit is not set, then the subroutine 
// should return 0.
// OUTPUT: A1 -> RVALID bit
read_PS2_data_ASM:
    PUSH {V1-V2, LR}
    LDR V1, =KBD_REGISTER // Load address of data register
    LDR V2, [V1] // Load contents of data register into V2
    LSR V2, #15 // Shift right by 15 bits
    AND A1, V2, #0x1 // Return MSB read i.e. RVALID bit in A1
    POP {V1-V2, PC}





/*---------- INTERRUPTS CONFIGURATION ----------*/

CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* NOTE: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT

/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}
	
/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}

// This subroutine is the interrupt service routine for the PS/2 keyboard
PS2_ISR:
    