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

Keyboard_check:
    CMP R5, #79         // Check if ID of interrupt raiser is PS/2's

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
.equ CHAR_BUFFER, 0xC9000000  // Chracter buffer base address
.equ KBD_REGISTER, 0xFF200100 // PS/2 data register address

DATA: .word 0 // Current keyboard data set to 0 initially. It will hold the make signal of the most recently pressed key.
CURSOR_POS: .byte 0, 0 // Current cursor position (x, y) -> First byte is x position, second is y position
            .space 2

// GoLBoardInitialState is the initial state of the game board we want to start at. Every time the user restarts the game,
// it will be set to the state of GoLBoardInitialState
GoLBoardInitialState:
    //  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.byte 0,1,1,1,0,1,1,1,0,1,1,1,0,1,1,1 // 1
	.byte 0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0 // 2
	.byte 0,1,1,0,0,1,0,0,0,1,1,1,0,1,1,0 // 3
	.byte 0,1,0,0,0,1,0,0,0,0,0,1,0,1,0,0 // 4
	.byte 0,1,1,1,0,1,1,1,0,1,1,1,0,1,1,1 // 5
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 6
	.byte 0,0,1,1,1,0,1,1,1,0,1,0,1,0,0,0 // 7
	.byte 0,0,0,0,1,0,0,0,1,0,1,0,1,0,0,0 // 8
	.byte 0,0,0,1,0,0,0,1,0,0,1,1,1,0,0,0 // 9
	.byte 0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0 // a
	.byte 0,0,1,1,1,0,1,1,1,0,0,0,1,0,0,0 // b

// GoLBoard holds the current state of the game of life board -> 1 = cell is active, 0 = cell is inactive
GoLBoard:
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 2
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 3
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 4
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 5
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 6
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 7
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 8
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 9
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // a
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b

// GoLBoardMirror mirrors the GoLBoard, but each of its cells holds the number of active neighbors it has.
GoLBoardMirror:
    //  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 2
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 3
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 4
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 5
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 6
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 7
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 8
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 9
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
    
    // UPDATE GoLBoard's state to GoLBoardInitialState's state
    MOV A1, #0             // Instantiate y index
    LDR V1, =GoLBoardInitialState
    LDR V2, =GoLBoard

    row_setup_loop:
        MOV A2, #0         // Instantiate x index

    col_setup_loop:
        MOV A3, A1         // Move y index into A3 (use A3 to hold offset)
        LSL A3, #4         // Multiply by 16 to compute y offset
        ADD A3, A3, A2     // Add in x offset
        LDRB A4, [V1, A3]  // Load in initial state of cell into A4
        STRB A4, [V2, A3]  // Store that initial state into current state of game board
        ADD A2, A2, #1     // Increment x index
        CMP A2, #16        // Check if x = 16 (break if so)
        BNE col_setup_loop // If not, then keep going

    row_setup_loop_end:
        ADD A1, A1, #1     // Increment y index
        CMP A1, #12        // Check if y = 12 (break if so)
        BNE row_setup_loop // If not, then keep looping

    // ENABLING INTERRUPTS FOR KEYBOARD
    LDR A1, =KBD_REGISTER  // Load keyboard register address
    MOV A2, #1
    STR A2, [A1, #4]       // Enable interrupts for the keyboard

    // CLEAR PIXEL BUFFER
    BL VGA_clear_pixelbuff_ASM
    
    // DRAW GRID LINES
    MOV A1, #0xff
    LSL A1, #8
    ADD A1, A1, #0xff      // Instantiate white colour
    BL GoL_draw_grid_ASM

    // SETUP CURSOR POSITION
    LDR A1, =CURSOR_POS
    MOV A2, #0
    STRB A2, [A1]
    STRB A2, [A1, #1]

    // FILL IN GRID CELLS
    MOV A1, #0xff          // Colour blue
    BL GoL_draw_board_ASM

    // UPDATE GoLBoardMirror
    BL update_GoL_mirror

IDLE:
    // POLL DATA VARIABLE
    LDR V1, =DATA         // Load address of DATA variable
    LDR A1, [V1]          // Load variable contents into A1
    CMP A1, #0x1D         // W key press
    BEQ move_cursor_up
    CMP A1, #0x1C         // A key press
    BEQ move_cursor_left
    CMP A1, #0x1B         // S key press
    BEQ move_cursor_down
    CMP A1, #0x23         // D key press
    BEQ move_cursor_right
    CMP A1, #0x29         // Spacebar key press
    BEQ toggle_state
    CMP A1, #0x31         // N key press
    BEQ update_GoL_board
    B IDLE                // Continue polling

move_cursor_up:
    LDR V1, =CURSOR_POS      // Load address of cursor position
    LDRB A2, [V1, #1]        // Get 2nd byte -> y position
    LDRB A1, [V1]            // Get 1ast byte -> x position
    LDR V2, =GoLBoard        // Load address of game board
    MOV V3, A2               // Move y into V3
    LSL V3, #4               // Compute y offset (multiply by 16)
    ADD V3, V3, A1           // Add x offset
    LDRB V4, [V2, V3]        // Get byte at base address + offset
    CMP V4, #1               // Check if state of cell at (x, y) is on
    MOVEQ A3, #0xff          // Move blue into A3 for colour if so
    MOVNE A3, #0x0           // Else move black into A3
    SUB V3, V3, A1           // Subtract x offset
    LSR V3, #4               // Divide by 16 to get original y
    MOV V4, A1               // Move x into V4
    BL GoL_fill_gridxy_ASM   // Clear cursor in current position
    CMP V3, #0               // Check if y is at 0
    SUBNE V3, V3, #1         // Decrement by 1 if y != 0
    STRB V3, [V1, #1]        // Store new y position into memory
    // DRAW CURSOR
    MOV A1, V4               // Move x into A1
    MOV A2, V3               // Move y into A2
    MOV A3, #0xff
    LSL A3, #8
    ADD A3, A3, #0xff        // Instantiate white color
    BL GoL_draw_cursorxy_ASM // Draw cursor
	// CLEAR DATA VARIABLE UNTIL ISR CHANGES IT AGAIN
   	LDR V1, =DATA
   	MOV A1, #0x0             // Write 0 to data location in memory
    STR A1, [V1]
	B IDLE

move_cursor_down:
    LDR V1, =CURSOR_POS      // Load address of cursor position
    LDRB A2, [V1, #1]        // Get 2nd byte -> y position
    LDRB A1, [V1]            // Get 1ast byte -> x position
    LDR V2, =GoLBoard        // Load address of game board
    MOV V3, A2               // Move y into V3
    LSL V3, #4               // Compute y offset (multiply by 16)
    ADD V3, V3, A1           // Add x offset
    LDRB V4, [V2, V3]        // Get byte at base address + offset
    CMP V4, #1               // Check if state of cell at (x, y) is on
    MOVEQ A3, #0xff          // Move blue into A3 for colour if so
    MOVNE A3, #0x0           // Else move black into A3
    SUB V3, V3, A1           // Subtract x offset
    LSR V3, #4               // Divide by 16 to get original y
    MOV V4, A1               // Move x into V4
    BL GoL_fill_gridxy_ASM   // Clear cursor in current position
    CMP V3, #11              // Check if y is at 11
    ADDNE V3, V3, #1         // Increment by 1 if y != 0
    STRB V3, [V1, #1]        // Store new y position into memory
    // DRAW CURSOR
    MOV A1, V4               // Move x into A1
    MOV A2, V3               // Move y into A2
    MOV A3, #0xff
    LSL A3, #8
    ADD A3, A3, #0xff        // Instantiate white color
    BL GoL_draw_cursorxy_ASM // Draw cursor
	// CLEAR DATA VARIABLE UNTIL ISR CHANGES IT AGAIN
   	LDR V1, =DATA
   	MOV A1, #0x0             // Write 0 to data location in memory
    STR A1, [V1]
	B IDLE

move_cursor_left:
    LDR V1, =CURSOR_POS      // Load address of cursor position
    LDRB A2, [V1, #1]        // Get 2nd byte -> y position
    LDRB A1, [V1]            // Get 1ast byte -> x position
    LDR V2, =GoLBoard        // Load address of game board
    MOV V3, A2               // Move y into V3
    LSL V3, #4               // Compute y offset (multiply by 16)
    ADD V3, V3, A1           // Add x offset
    LDRB V4, [V2, V3]        // Get byte at base address + offset
    CMP V4, #1               // Check if state of cell at (x, y) is on
    MOVEQ A3, #0xff          // Move blue into A3 for colour if so
    MOVNE A3, #0x0           // Else move black into A3
    SUB V3, V3, A1           // Subtract x offset
    LSR V3, #4               // Divide by 16 to get original y
    MOV V4, A1               // Move x into V4
    BL GoL_fill_gridxy_ASM   // Clear cursor in current position
    CMP V4, #0               // Check if x is at 0
    SUBNE V4, V4, #1         // Decrement by 1 if x != 0
    STRB V4, [V1]            // Store new x position into memory
    // DRAW CURSOR
    MOV A1, V4               // Move x into A1
    MOV A2, V3               // Move y into A2
    MOV A3, #0xff
    LSL A3, #8
    ADD A3, A3, #0xff        // Instantiate white color
    BL GoL_draw_cursorxy_ASM // Draw cursor
	// CLEAR DATA VARIABLE UNTIL ISR CHANGES IT AGAIN
   	LDR V1, =DATA
   	MOV A1, #0x0             // Write 0 to data location in memory
    STR A1, [V1]
	B IDLE

move_cursor_right:
    LDR V1, =CURSOR_POS      // Load address of cursor position
    LDRB A2, [V1, #1]        // Get 2nd byte -> y position
    LDRB A1, [V1]            // Get 1ast byte -> x position
    LDR V2, =GoLBoard        // Load address of game board
    MOV V3, A2               // Move y into V3
    LSL V3, #4               // Compute y offset (multiply by 16)
    ADD V3, V3, A1           // Add x offset
    LDRB V4, [V2, V3]        // Get byte at base address + offset
    CMP V4, #1               // Check if state of cell at (x, y) is on
    MOVEQ A3, #0xff          // Move blue into A3 for colour if so
    MOVNE A3, #0x0           // Else move black into A3
    SUB V3, V3, A1           // Subtract x offset
    LSR V3, #4               // Divide by 16 to get original y
    MOV V4, A1               // Move x into V4
    BL GoL_fill_gridxy_ASM   // Clear cursor in current position
    CMP V4, #15              // Check if x is at 15
    ADDNE V4, V4, #1         // Increment by 1 if x != 0
    STRB V4, [V1]            // Store new x position into memory
    // DRAW CURSOR
    MOV A1, V4               // Move x into A1
    MOV A2, V3               // Move y into A2
    MOV A3, #0xff
    LSL A3, #8
    ADD A3, A3, #0xff        // Instantiate white color
    BL GoL_draw_cursorxy_ASM // Draw cursor
	// CLEAR DATA VARIABLE UNTIL ISR CHANGES IT AGAIN
   	LDR V1, =DATA
   	MOV A1, #0x0             // Write 0 to data location in memory
    STR A1, [V1]
	B IDLE

toggle_state:
    LDR V1, =CURSOR_POS      // Load address of cursor position into V1
    LDR V2, =GoLBoard        // Get game board base address in V2
    LDRB A1, [V1]            // Load x into A1
    LDRB A2, [V1, #1]        // Load y into A2
    LSL A2, #4               // Multiply y by 16 to get proper row offset
    ADD A1, A2, A1           // Add in x offset
    LDRB A3, [V2, A1]        // Get cell (x, y)'s state
    EOR A3, #1               // XOR with 1 to get complementary
    STRB A3, [V2, A1]        // Store new state into memory
    // UPDATE CELL AT POSITION X, Y
    LDR V1, =CURSOR_POS      // Load address of cursor position
    LDRB A1, [V1]            // Load x into A1
    LDRB A2, [V1, #1]        // Load y into A2
    CMP A3, #1               // Check if current cell is 1
    MOVEQ A3, #0xff          // Move colour blue if state is 1
    MOVNE A3, #0x0           // Else, move colour black if state is 0
    BL GoL_fill_gridxy_ASM   // Fill the grid with the appropriate colour
    // DRAW CURSOR
    LDRB A1, [V1]            // Load x into A1
    LDRB A2, [V1, #1]        // Load y into A2
    MOV A3, #0xff
    LSL A3, #8
    ADD A3, A3, #0xff        // Instantitate white colour
    BL GoL_draw_cursorxy_ASM // Draw the cursor over updated cell
    BL update_GoL_mirror     // Update board mirror
    // CLEAR DATA VARIABLE UNTIL ISR CHANGES IT AGAIN
   	LDR V1, =DATA
   	MOV A1, #0x0             // Write 0 to data location in memory
    STR A1, [V1]
    B IDLE

update_GoL_board:
    MOV V1, #0                   // Instantiate y index
    LDR V3, =GoLBoard
    LDR V4, =GoLBoardMirror

    for_each_row_in_board:
        CMP V1, #12              // Check y = 12 (termination condition)
        BEQ update_GoL_board_end
        MOV V2, #0               // Instantiate x index

    for_each_col_in_board:
        CMP V2, #16              // Check x = 16 (termination condition)
        BEQ for_each_row_in_board_end

        MOV A1, V1               // Move y index into A1 (use to hold offset)
        LSL A1, #4               // Multiply by 16
        ADD A1, A1, V2           // Add in x offset
        LDRB A2, [V3, A1]        // Load cell value of game board
        CMP A2, #1               // Check if cell value is active in game board
        BEQ check_active_cell_condtions
        BNE check_inactive_cell_conditions
    
    check_active_cell_condtions:
        MOV A2, #1               // Originally, set status of cell to be active
        LDRB A3, [V4, A1]        // Load cell value of game board mirror
        CMP A3, #1               // Check if cell value in game board mirror is less than or equal to 1
        MOVLE A2, #0             // If so, cell becomes inactive
        CMP A3, #4               // Check if cell value in game board mirror is greater or equal to 4
        MOVGE A2, #0             // If so, cell value becomes inactive
        MOV A1, V1               // Move y index into A1 (use to hold offset)
        LSL A1, #4               // Multiply by 16
        ADD A1, A1, V2           // Add in x offset
        STRB A2, [V3, A1]        // Store new status of cell into memory
        B for_each_col_in_board_end 

    check_inactive_cell_conditions:
        MOV A2, #0               // Originally, set status of cell to be inactive
        LDRB A3, [V4, A1]        // Load cell value of game board mirror
        CMP A3, #3               // Check if inactive cell has exactly 3 active neighbours
        MOVEQ A2, #1             // If so, cell value becomes active
        MOV A1, V1               // Move y index into A1 (use to hold offset)
        LSL A1, #4               // Multiply by 16
        ADD A1, A1, V2           // Add in x offset
        STRB A2, [V3, A1]        // Store new status of cell into memory
        B for_each_col_in_board_end 

    for_each_col_in_board_end:
        ADD V2, V2, #1           // Increment index
        B for_each_col_in_board

    for_each_row_in_board_end:
        ADD V1, V1, #1           // Increment y index
        B for_each_row_in_board

    update_GoL_board_end:
        MOV A1, #0xff
        BL GoL_draw_board_ASM    // Update displayed board
        LDR V1, =CURSOR_POS
        LDRB A1, [V1]            // Load cursor x into A1
        LDRB A2, [V1, #1]        // Load cursor y into A2
        MOV A3, #0xff
        LSL A3, #8
        ADD A3, A3, #0xff        // Instantiate white colour
        BL GoL_draw_cursorxy_ASM // Draw cursor
        BL update_GoL_mirror     // Update the mirror of the board as well
        // CLEAR DATA VARIABLE UNTIL ISR CHANGES IT AGAIN
   	    LDR V1, =DATA
   	    MOV A1, #0x0             // Write 0 to data location in memory
        STR A1, [V1]
        B IDLE





/*---------- GoL DRIVERS ----------*/

// This subroutine passes over the GoL board and updates the number of active neighbours for every cell.
update_GoL_mirror:
    PUSH {V1-V3, LR}
    MOV V1, #0 // Instantiate y index
    LDR V3, =GoLBoardMirror
    
    for_each_row_in_mirror:
        CMP V1, #12 // Check y = 12 (termination condition)
        BEQ update_GoL_mirror_end
        MOV V2, #0 // Instantiate x index

    for_each_col_in_mirror:
        CMP V2, #16 // Check x = 16 (termination condition)
        BEQ for_each_row_in_mirror_end
        MOV A1, V2 // Move x into A1
        MOV A2, V1 // Move y into A2
        BL find_num_of_neighboursxy // Find number of neighbours of current cell (returned in A1)
        MOV A2, V1 // Move y into A2 (use A2 as register to hold offset)
        LSL A2, #4 // Multiply by 16
        ADD A2, A2, V2 // Add in x offset
        STRB A1, [V3, A2] // Store number of neighbours into mirror map
        ADD V2, V2, #1 // Increment x index
        B for_each_col_in_mirror

    for_each_row_in_mirror_end:
        ADD V1, V1, #1 // Increment y index
        B for_each_row_in_mirror

    update_GoL_mirror_end:
        POP {V1-V3, PC}

// This subroutine returns the number of active neighbours given an (x, y) coordinate.
// Note: 0 <= x < 16, 0 <= y < 12
// INPUT: A1 -> x, A2 -> y
// OUTPUT: A1 -> number of active neighbours of (x, y)
find_num_of_neighboursxy:
    PUSH {V1-V3, LR}
    // INPUT VALIDATION
    CMP A1, #0
    BLT find_num_of_neighboursxy_end // Exit if x < 0
    CMP A1, #16
    BGE find_num_of_neighboursxy_end // Exit if x >= 16
    CMP A2, #0
    BLT find_num_of_neighboursxy_end // Exit if y < 0
    CMP A2, #12
    BGE find_num_of_neighboursxy_end // Exit if y >= 12
    // SUBROUTINE LOGIC
    LDR V1, =GoLBoard
    LDR V2, =GoLBoardMirror
    MOV V3, #0 // Instantiate result to 0
    
    check_top_left: // Check coordinate (x-1, y-1)
        CMP A1, #0 // Check if x = 0
        BEQ check_top // If it is, then skip since col out of bounds
        CMP A2, #0 // Check if y = 0
        BEQ check_top // If it is, then skip since col out of bounds
        SUB A1, A1, #1 // x = x-1
        SUB A2, A2, #1 // y = y-1
        MOV A3, A2 // Move y into A3 -> it holds offset
        LSL A3, #4 // Multiply by 16
        ADD A3, A3, A1 // Add in x offset
        LDRB A4, [V1, A3] // Load board cell value
        CMP A4, #1 // Check if (x-1, y-1) = 1
        ADDEQ V3, V3, #1 // If it is, then increment result by 1
        ADD A1, A1, #1 // x-1 = x
        ADD A2, A2, #1 // y-1 = y

    check_top: // Check coordinate (x, y-1)
        CMP A2, #0 // Check if y = 0
        BEQ check_top_right // If it is, then skip since row out of bounds
        SUB A2, A2, #1 // y = y+1
        MOV A3, A2 // Move y into A3 -> hold offset
        LSL A3, #4 // Multiply by 16
        ADD A3, A3, A1 // Add in x offset
        LDRB A4, [V1, A3] // Load board cell value
        CMP A4, #1 // Check if (x, y-1) = 1
        ADDEQ V3, V3, #1 // If it is, then increment result by 1
        ADD A2, A2, #1 // y-1 = y

    check_top_right: // Check coordinate (x+1, y-1)
        CMP A1, #15 // Check if x = 15
        BEQ check_left // If it is, then skip since col out of bounds
        CMP A2, #0 // Check if y = 0
        BEQ check_left // If it is, then skip since row out of bounds
        ADD A1, A1, #1 // x = x+1
        SUB A2, A2, #1 // y = y-1
        MOV A3, A2 // Move y into A3 -> hold offset
        LSL A3, #4 // Multiply by 16
        ADD A3, A3, A1 // Add in x offset
        LDRB A4, [V1, A3] // Load board cell value
        CMP A4, #1 // Check if (x+1, y-1) = 1
        ADDEQ V3, V3, #1 // If it is, then increment result by 1
        SUB A1, A1, #1 // x+1 = x
        ADD A2, A2, #1 // y-1 = y

    check_left: // Check coordinate (x-1, y)
        CMP A1, #0 // Check if x = 0
        BEQ check_right // If it is, then skip since col out of bounds
        SUB A1, A1, #1 // x = x-1
        MOV A3, A2 // Move y into A3 -> hold offset
        LSL A3, #4 // Multiply by 16
        ADD A3, A3, A1 // Add in x offset
        LDRB A4, [V1, A3] // Load board cell value
        CMP A4, #1 // Check if (x-1, y) = 1
        ADDEQ V3, V3, #1 // If it is, then increment result by 1
        ADD A1, A1, #1 // x-1 = x

    check_right: // Check coordinate (x+1, y)
        CMP A1, #15 // Check if x = 15
        BEQ check_bottom_left // If it is, then skip since col out of bounds
        ADD A1, A1, #1 // x = x+1
        MOV A3, A2 // Move y into A3 -> hold offset
        LSL A3, #4 // Multiply by 16
        ADD A3, A3, A1 // Add in x offset
        LDRB A4, [V1, A3] // Load board cell value
        CMP A4, #1 // Check if (x+1, y) = 1
        ADDEQ V3, V3, #1 // If it is, then increment result by 1
        SUB A1, A1, #1 // x+1 = x

    check_bottom_left: // Check coordinate (x-1, y+1)
        CMP A1, #0 // Check if x = 0
        BEQ check_bottom // If it is, then skip since col out of bounds
        CMP A2, #11 // Check if y = 11
        BEQ check_bottom // If it is, then skip since row out of bounds
        SUB A1, A1, #1 // x = x-1
        ADD A2, A2, #1 // y = y+1
        MOV A3, A2 // Move y into A3 -> hold offset
        LSL A3, #4 // Multiply by 16
        ADD A3, A3, A1 // Add in x offset
        LDRB A4, [V1, A3] // Load board cell value
        CMP A4, #1 // Check if (x-1, y+1) = 1
        ADDEQ V3, V3, #1 // If it is, then increment result by 1
        ADD A1, A1, #1 // x-1 = x
        SUB A2, A2, #1 // y+1 = y

    check_bottom: // Check coordinate (x, y+1)
        CMP A2, #11 // Check if y = 11
        BEQ check_bottom_right // If it is, then skip since row out of bounds
        ADD A2, A2, #1 // y = y+1
        MOV A3, A2 // Move y into A3 -> hold offset
        LSL A3, #4 // Multiply by 16
        ADD A3, A3, A1 // Add in x offset
        LDRB A4, [V1, A3] // Load board cell value
        CMP A4, #1 // Check if (x, y+1) = 1
        ADDEQ V3, V3, #1 // If it is, then increment result by 1
        SUB A2, A2, #1 // y+1 = y

    check_bottom_right: // Check coordinate (x+1, y+1)
        CMP A1, #15 // Check if x = 15
        BEQ find_num_of_neighboursxy_end // If it is, then skip since col out of bounds
        CMP A2, #11 // Check if y = 11
        BEQ find_num_of_neighboursxy_end // If it is, then skip since row out of bounds
        ADD A1, A1, #1 // x = x+1
        ADD A2, A2, #1 // y = y+1
        MOV A3, A2 // Move y into A3 -> hold offset
        LSL A3, #4 // Multiply by 16
        ADD A3, A3, A1 // Add in x offset
        LDRB A4, [V1, A3] // Load board cell value
        CMP A4, #1 // Check if (x+1, y+1) = 1
        ADDEQ V3, V3, #1 // IF it is, then increment result by 1
        SUB A1, A1, #1 // x+1 = x
        SUB A2, A2, #1 // y+1 = y

    find_num_of_neighboursxy_end:
        MOV A1, V3 // Move result into A1
        POP {V1-V3, PC}

// This subroutine draws a cursor at location (x, y), 0 <= x < 16, 0 <= y < 12 with colour c
// INPUTS: A1 -> x, A2 -> y, A3 -> Colour c
GoL_draw_cursorxy_ASM:
    PUSH {V1-V4, LR}
    // INPUT VALIDATION
    CMP A1, #0
    BLT GoL_draw_cursorxy_ASM_end // Exit if x < 0
    CMP A1, #16
    BGE GoL_draw_cursorxy_ASM_end // Exit if x >= 16
    CMP A2, #0
    BLT GoL_draw_cursorxy_ASM_end // Exit if y < 0
    CMP A2, #12
    BGE GoL_draw_cursorxy_ASM_end // Exit if y >= 12
    // CALCULATING PIXEL X & Y
    MOV V4, #20 // Move constant 20 into V4
    MOV V1, A1 // Move x to V1
    MUL V1, V1, V4 // Multiply x by 20 to get pixel x-coordinate
    ADDNE V1, V1, #1 // Add 1 to x1
    MOV V2, A2 // Move y to V2
    MUL V2, V2, V4 // Multiply y by 20 to get pixel y-coordinate
    ADDNE V2, V2, #1 // Add 1 to y1
    // DRAWING CURSOR
    MOV A1, V1 // Move x into A1
    MOV A2, V2 // Move y into A2
    ADD A1, A1, #6
    ADD A2, A2, #6
    BL VGA_draw_point_ASM
    ADD A1, A1, #6
    BL VGA_draw_point_ASM
    ADD A2, A2, #1
    SUB A1, A1, #5
    BL VGA_draw_point_ASM
    ADD A1, A1, #4
    BL VGA_draw_point_ASM
    ADD A2, A2, #1
    SUB A1, A1, #5
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A2, A2, #1
    SUB A1, A1, #7
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #2
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #2
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A2, A2, #1
    SUB A1, A1, #9
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A2, A2, #1
    SUB A1, A1, #10
    BL VGA_draw_point_ASM
    ADD A1, A1, #2
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #2
    BL VGA_draw_point_ASM
    ADD A2, A2, #1
    SUB A1, A1, #10
    BL VGA_draw_point_ASM
    ADD A1, A1, #2
    BL VGA_draw_point_ASM
    ADD A1, A1, #6
    BL VGA_draw_point_ASM
    ADD A1, A1, #2
    BL VGA_draw_point_ASM
    ADD A2, A2, #1
    SUB A1, A1, #7
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM
    ADD A1, A1, #2
    BL VGA_draw_point_ASM
    ADD A1, A1, #1
    BL VGA_draw_point_ASM

    GoL_draw_cursorxy_ASM_end:
        POP {V1-V4, PC}

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
        MOV A1, V2 // Move column index (x) into A1 if value is 1
        MOV A2, V1 // Move row index (y) into A2 if value is 1
        LSLNE A3, #16 // Shift up 16 to leave lower 16 bits as 0 (and hence colour the cell black) if vaue is 0
        BL GoL_fill_gridxy_ASM // Fill grid cell at (x, y) if value is 1
        CMP V4, #1 // Check if value is 1 to re-update CPSR
        LSRNE A3, #16 // Shift colour back down 16
        
        // CHECK IF CURRENT (X, Y) EQUALS CURSOR'S POSITION
        LDR A4, =CURSOR_POS // Load cursor position address into A4
        LDRH A1, [A4] // Load half-word content into A1 -> (x, y) = 2 bytes
        MOV A2, V1 // Move row index into A2
        LSL A2, #8 // Shift up by one byte
        ADD A2, A2, V2 // Add in column index
        CMP A1, A2 // Check if current (x, y) is equal to cursor position
        MOV A1, V2 // Move col index into A1
        MOV A2, V1 // Move row index into A2
        PUSH {A3} // Store colour variable (blue)
        MOV A3, #0xff
        LSL A3, #8
        ADD A3, A3, #0xff // Instantiate white colour
        BLEQ GoL_draw_cursorxy_ASM // Draw cursor in white
        POP {A3} // Restore original colour (blue)

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
    PUSH {V1-V4, LR}
    LDR V1, =KBD_REGISTER // Load address of data register
    LDR V2, [V1] // Load contents of data register into V2
    MOV V3, V2 // Duplicate data into V3
    LSR V2, #15 // Shift right by 15 bits
    AND A1, V2, #0x1 // Return MSB read i.e. RVALID bit in A1
    LDR V4, =DATA // Load address of DATA variable in memory
    AND V3, V3, #0xff // Keep only last 8 bits (data content)
    STR V3, [V4] // Store into memory
    POP {V1-V4, PC}





/*---------- INTERRUPTS CONFIGURATION ----------*/

CONFIG_GIC:
    PUSH {LR}
    /* To configure the PS/2 keyboard interrupt (ID 79):
    * 1. set the target to cpu0 in the ICDIPTRn register
    * 2. enable the interrupt in the ICDISERn register */
    /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
    /* NOTE: you can configure different interrupts
    by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #79            // KEY port (Interrupt ID = 79)
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
    PUSH {V1-V2, LR}
    LDR V1, =DATA // Load address of DATA variable
    MOV A2, #0 // Clear A2
    MOV V2, #0x80 // Delay counterset to 128

    // This delay loop is a rudimentary solution to a problem. The break signal's byte are sent with a silght delay. However,
    // considering the CPU's blazing frequency, the second byte of the break signal is often not capted. Therefore, we just
    // implement a delay loop to give the keyboard's data register some time to update.
    delay_loop:
        CMP V2, #0
        BEQ clear_kbd_data_reg
        SUB V2, V2, #1
        B delay_loop

    clear_kbd_data_reg:
        BL read_PS2_data_ASM // Check RVALID bit (returned in A1)
        CMP A1, #0 // Check if RVALID = 0
        BEQ PS2_ISR_end // Exit once data register is empty
		LDR A3, [V1] // Load data variable into A3
        LSL A2, #8 // Shift up by a byte
        ORR A2, A2, A3 // Add DATA byte
        B clear_kbd_data_reg // Keep looping until data register of PS/2 is empty

    PS2_ISR_end:
		STR A2, [V1] // Store all keyboard signals in FIFO into memory
        POP {V1-V2, PC}