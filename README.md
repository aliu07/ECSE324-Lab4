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

## PS/2 Dribers
The PS/2 keyboard drivers enable keypress interactions. It utilizes the VGA drivers to write whatever is read from the keyboard's data register to the display using a built-in character font. Running the PS/2 drivers is similar to the VGA drivers. It can be summed as follows:
1. Copy-paste the ps2.s file contents into the emulator.
2. Click the compile button.
3. Click the continue button to run the program.
4. This time, you will need to interact with the keyboard I/O device. **Make sure you select the PS/2 keyboard starting at address 0xff200100**. You can send data to the keyboard by pressing keys on your actual keyboard or by selecting a character and clicking the corresponding send button to send either the make or break signal. An example of output is also provided below.
![Screenshot 2024-04-22 at 9 59 36 PM](https://github.com/aliu07/ECSE324-Lab4/assets/114955212/7776e4eb-7f65-4c2a-8961-b3e0e4c67e74)
