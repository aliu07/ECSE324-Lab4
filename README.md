# Conway's Game of Life
This project is inspired from British mathematician John Horton Conway's game of life. The repository features drivers for the VGA display fo the emulator as well as the PS/2 keyboard. The emulator can be accessed at the following link: https://ecse324.ece.mcgill.ca/simulator/?sys=arm-de1soc

## VGA Drivers
The VGA driver file, called vga.s, contains code that writes to the display of the emulator. To run the code and see its output, walk through the following steps:
1. Copy-paste the vga.s file contents into the emulator.
2. Click the compile button.
![How to - compile code in emulator](https://github.com/aliu07/ECSE324-Lab4/assets/114955212/8ad2b2e7-4520-49fe-a9ab-6af855642e77)
3. Click the continue button to run the program.
![Screenshot 2024-04-22 at 9 46 30 PM](https://github.com/aliu07/ECSE324-Lab4/assets/114955212/9ddaf3db-f785-4bca-9217-1f51c845ae83)
4. The output will be visible on the emulated VGA display. This display can be found on the right-hand side of the emulator UI where all the I/O devices are located.
<img width="1440" alt="Screenshot 2024-04-22 at 9 49 44 PM" src="https://github.com/aliu07/ECSE324-Lab4/assets/114955212/739b6434-e1aa-406d-854c-da2b8a168818">

## PS/2 Drivers
The PS/2 keyboard drivers enable keypress interactions. It utilizes the VGA drivers to write whatever is read from the keyboard's data register to the display using a built-in character font. Running the PS/2 drivers is similar to the VGA drivers. It can be summed as follows:
1. Copy-paste the ps2.s file contents into the emulator.
2. Click the compile button.
3. Click the continue button to run the program.
4. This time, you will need to interact with the keyboard I/O device. **Make sure you select the PS/2 keyboard starting at address 0xff200100**. You can send data to the keyboard by pressing keys on your actual keyboard or by selecting a character and clicking the corresponding send button to send either the make or break signal. An example of output is also provided below.
![Screenshot 2024-04-22 at 9 59 36 PM](https://github.com/aliu07/ECSE324-Lab4/assets/114955212/7776e4eb-7f65-4c2a-8961-b3e0e4c67e74)

## Conway's Game of Life
This is where everything is incorporated together. Drivers for the VGA display and the PS/2 keyboard are used to render an interactive version of the game of life. Here are the important game controls:
- W, A, S, D to control the cursor
- Spacebar to toggle the state of a cell (black = inactive, blue = active)
- N to advance to the next game state (i.e. update the board to get the next state)

To provide more insight on how game mechanics, the rules can be summed up as so:
- Any active cell with 0 or 1 active neighbours becomes inactive
- Any active cell with 2 or 3 active neighbours remains active
- Any active cell with 4 or more active neighbours becomes inactive
- Any inactive cell with exactly 3 neighbours becomes active.

The process to setup the game is similar to the drivers:
1. Copy-paste the contents of the game_of_life.s file contents into the emulator.
2. Click the compile button.
3. Click the continue button to run the program.
4. You can play the game interactively through the PS/2 keyboard and see anyresulting game state updates in the VGA display. For reference, an image of an example game state has been provided below.
![Screenshot 2024-04-22 at 10 09 42 PM](https://github.com/aliu07/ECSE324-Lab4/assets/114955212/d3da0c4d-81dd-4252-940b-922c809eb1e6)

You will notice that the file containing the game of life is fairly large. We did not get hands on practice with linkers in this assembly course. However, it would be an interesting topic to look into in order to separate the code more neatly.
