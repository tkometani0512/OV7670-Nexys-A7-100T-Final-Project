# OV7670-Nexys-A7-100T-Final-Project

## Project Description

This project captures live video from an OV7670 camera module and displays it
on a VGA monitor using a Nexys A7 100T FPGA board. The camera feed is captured
in real time, stored in a Block RAM frame buffer, and displayed centered within
an 800×600 VGA output. The 320×240 captured image is scaled 2×2 per pixel to
fill a 640×480 area centered on screen with black borders on all sides.

The system operates entirely in hardware with no processor all pixel capture,
buffering, and display logic is implemented in VHDL running on the FPGA.

Two user controls are provided via onboard switches: a freeze frame switch that
holds the current frame on screen indefinitely, and a color invert filter that
produces a real time color negative effect.

---

## System Block Diagram
<img width="1920" height="1080" alt="OV7670_Capture" src="https://github.com/user-attachments/assets/20a869c3-8647-4b17-93fe-b83cae1d2318" />

## FSM for ov7670_capture.vhd 
<img width="1920" height="1080" alt="WAIT_VSYNC" src="https://github.com/user-attachments/assets/c5c09f33-297a-41c4-a1d9-57e9be365cf5" />

---

## Attachments Needed

- Nexys A7 100T FPGA board
- OV7670 camera module without FIFO (HiLetgo 2 pack used in this project)
- Any VGA capable monitor
- HDMI to VGA adapter if monitor only has HDMI input
- Breadboard
- Jumper wires (male to male)
- USB cable for programming the Nexys board

---

## Steps to Get the Project Working in Vivado

1. Clone this repository
2. Open Vivado and create a new RTL project targeting the Nexys A7 100T (xc7a100tcsg324-1)
3. Add all source files:
   - `clk_wiz_0.vhd`
   - `clk_wiz_0_clk_wiz.vhd`
   - `vga_sync.vhd`
   - `frame_buffer.vhd`
   - `ov7670_capture.vhd`
   - `i2c_config.vhd`
   - `camera_top.vhd`
4. Add `camera.xdc` as the constraint file
5. Set `camera_top` as the top module
6. Connect the OV7670 camera to the Nexys A7 Pmod headers as described below
7. Click Generate Bitstream
8. Once complete connect your board and click Program Device
9. The camera feed will appear on screen within 1 to 2 seconds as the
   I2C configuration completes

---

## Inputs and Outputs

### Inputs to Nexys A7

| Signal | Pin | Description |
|--------|-----|-------------|
| clk_in | E3 | 100MHz on-board system clock |
| cam_pclk | H16 (JB10) | Pixel clock from camera, one byte per pulse |
| cam_vsync | D14 (JB1) | Vertical sync, pulses high at start of each frame |
| cam_href | F16 (JB2) | High when a row of pixels is being transmitted |
| cam_d[0] | C17 (JA1) | Camera data bit 0 |
| cam_d[1] | D18 (JA2) | Camera data bit 1 |
| cam_d[2] | E18 (JA3) | Camera data bit 2 |
| cam_d[3] | G17 (JA4) | Camera data bit 3 |
| cam_d[4] | D17 (JA7) | Camera data bit 4 |
| cam_d[5] | E17 (JA8) | Camera data bit 5 |
| cam_d[6] | F18 (JA9) | Camera data bit 6 |
| cam_d[7] | G18 (JA10) | Camera data bit 7 |
| sw_freeze | J15 (SW0) | Slide up to freeze current frame |
| sw_invert | L16 (SW1) | Slide up to enable color invert filter |

### Outputs from Nexys A7

| Signal | Pin | Description |
|--------|-----|-------------|
| cam_xclk | H14 (JB4) | 24MHz clock supplied to drive the camera |
| cam_sioc | E16 (JB7) | I2C clock for camera configuration at startup |
| cam_siod | F13 (JB8) | I2C data for camera configuration at startup |
| VGA_hsync | B11 | VGA horizontal sync signal |
| VGA_vsync | B12 | VGA vertical sync signal |
| VGA_red[3:0] | A4,C5,B4,A3 | VGA red channel 4 bits |
| VGA_green[3:0] | A6,B6,A5,C6 | VGA green channel 4 bits |
| VGA_blue[3:0] | D8,D7,C7,B7 | VGA blue channel 4 bits |

### Camera Wiring
| OV7670 | Nexys A7 100T | 
D0     -> JA1  (C17)  
D1     -> JA2  (D18)  
D2     -> JA3  (E18)  
D3     -> JA4  (G17)  
D4     -> JA7  (D17)  
D5     -> JA8  (E17)  
D6     -> JA9  (F18)  
D7     -> JA10 (G18)  
VSYNC  -> JB1  (D14)  
HREF   -> JB2  (F16)  
XCLK   <- JB4  (H14)  
SIOC   <- JB7  (E16)  
SIOD  <-> JB8  (F13)  
PCLK   -> JB10 (H16)  
RESET  -> 3.3V directly (no FPGA pin needed)  
PWDN   -> GND  directly (no FPGA pin needed)  
3.3V   -> 3.3V rail  
GND    -> GND rail

---

## Modifications and New Features

### clk_wiz_0 / clk_wiz_0_clk_wiz (Modified from class starter code)
The original clock wizard generated a single output clock. A second output
clock (clk_out2) was added by configuring a second output channel
(CLKOUT1) with its own BUFG buffer. This second clock runs at approximately
24MHz and is fed directly to the camera XCLK pin to drive it.

### camera_top (Modified from pong top module)
Significant modifications were made to the top level:
- Added all camera input and output ports
- Instantiated frame_buffer, ov7670_capture, and i2c_config modules
- Added centering logic to display the 640×480 camera image centered
  within 800×600 with 80px left and right borders and 60px top and bottom borders
- Added BRAM read latency compensation using a registered address
  calculation and in_frame signal to correctly gate color output one
  cycle ahead of when vga_sync displays it
- Each camera pixel is displayed as a 2×2 block on screen, mapping the
  320×240 captured image to fill the 640×480 centered area
- Added SW1 invert filter and SW0 freeze frame user controls

### frame_buffer.vhd (Written from scratch)
A dual port Block RAM with:
- Port A: write port driven by ov7670_capture running on camera PCLK
- Port B: read port driven by vga_sync running on 40MHz display clock
- 76,800 locations (320×240 pixels), each storing 12 bits (4R 4G 4B)
- The two ports operate on completely independent clocks with no conflicts

### ov7670_capture.vhd (Written from scratch)
The capture module watches four camera signals: PCLK, VSYNC, HREF, and D[7:0].
It uses a three state FSM to parse the camera timing. WAIT_VSYNC idles until a
new frame begins. WAIT_HREF waits for a new row to start. CAPTURE reads pixels
byte by byte on every PCLK pulse. Since each pixel is 16 bits but the data bus
is only 8 bits wide, two PCLK pulses are needed per pixel. The first byte is
saved and the second byte is combined with it to form a complete 12 bit RGB
pixel which is then written to the frame buffer at the correct row and column
address.

### i2c_config.vhd (Written with AI assistance, register set from Mike Field with modifications to color mode)
Implements the SCCB protocol (I2C compatible) to configure approximately
60 OV7670 registers at startup. Key details:
- 25kHz SCCB clock
- 40ms power on delay before first transmission
- 50ms pause after software reset register
- Proper open drain SIOD using tri-state logic
- Register set sourced from Mike Field's proven OV7670 configuration

### User Controls (New inputs added after camera proven working)

**SW1 - Color Invert Filter**
When SW1 is slid up, all 12 bits of every pixel read from the frame buffer
are XORed with 1, producing a color negative effect in real time. XORing
with 0 leaves bits unchanged and XORing with 1 flips them, so the single
switch bit is replicated 12 times to form the XOR filter. The filter applies
with zero clock cycle latency as a concurrent signal assignment and works
correctly on both live and frozen frames.

**SW0 - Freeze Frame**
When SW0 is slid up, the PCLK signal fed to both the capture module and
the frame buffer write port is gated to zero. With no clock edges the
capture module cannot increment addresses or assert write enables, so the
frame buffer holds its last written frame indefinitely. The VGA read port
continues running normally, displaying the frozen frame. Slide SW0 down
to resume live feed.

---

## Current Status

- Generates correct 800×600 @ 60Hz VGA timing
- Centers a 640×480 camera area on the 800×600 display with black borders
- Captures live video from the OV7670 camera responding to light and motion
- Stores and retrieves frames using dual port Block RAM
- Configures the camera via I2C/SCCB at startup
- SW0 freeze frame working correctly
- SW1 color invert filter working correctly
  
- Color accuracy is still being tuned - the RGB channel mapping from
  the OV7670 byte stream requires further calibration for fully accurate colors.

---

## Images and Videos
<p align="center">
  <a href="https://youtube.com/shorts/P0I93yw5hII">
    <img src="youtube.com" width="350" alt="Watch Current Video!"/>
  </a>
</p>

---

## Summary

### Team Responsibilities

**Tyler Kometani** was responsible for all VHDL development including:
- All hardware design and implementation
- Debugging clock, VGA timing, and camera interface issues
- Writing frame_buffer.vhd and ov7670_capture.vhd from scratch
- Modifying clk_wiz_0, vga_sync, and camera_top from class starter code
- Implementing and debugging the I2C configuration module
- Adding freeze frame and invert filter user controls

**Bryan Barzola** was responsible for:
- Project documentation and poster
- Conceptual ideas to be implimented in VHDL

### Timeline

<img width="746" height="998" alt="image" src="https://github.com/user-attachments/assets/9ea8b3e4-35e0-484c-905f-a5cc04a9b1a3" />

<img width="742" height="992" alt="image" src="https://github.com/user-attachments/assets/203430c7-50ae-42f3-bdfb-5574dfa2f618" />

<img width="743" height="1002" alt="image" src="https://github.com/user-attachments/assets/1e504848-cea2-4e20-926b-65b9d1d9ccaf" />



<p align="center">
  <a href="https://youtube.com/shorts/6fLIcqSCFhU">
    <img src="youtube.com" width="350" alt="Before I2C"/>
  </a>
</p>




<p align="center">
  <a href="https://youtube.com/shorts/f6BBskVkmXg">
    <img src="youtube.com" width="350" alt="With I2C Before RGB444 configuration"/>
  </a>
</p>


### Difficulties Encountered

**Monitor compatibility**: The portable FANGOR monitor we home tested with did not support
640×480 @ 30Hz, requiring the the lab used 800×600 @ 60Hz and centering the
camera image within that resolution with black borders.

**Clock generation**: The original idea for modification of the clock wizard configuration
generated an incorrect frequency which caused color and image errors on monitor. This required us to make a new clk for the camera separate from the vga.

**BRAM read latency**: Block RAM takes one clock cycle to return data
after an address is presented. This caused the image border logic to be
offset by one pixel, requiring a registered address pipeline to compensate
so the in_frame gate signal and BRAM data arrive at the same time.

**Camera byte ordering**: The OV7670 outputs RGB444 data in GRB byte
order rather than the expected RGB order, causing incorrect colors. This
was identified by cross referencing Mike Field's OV7670 documentation
which explicitly notes the GRB ordering. Also some sources say that resistors are not already on the board on some models which could be the cause for our lasting issue detecting blue because our configuration may be slightly off without the resistors for the sioc and siod port.

**Wrong formatting and incorrect sizing** : our first attempt had the wrong display resolution compared to the cameras output so it gave noisy pixels across the whole screen. also our I2C configuration was wrong in the addresses so the color was wrong and noisy.

**Physical errors/stupid errors** : originally had very blurry video. After some coding troubleshooting thinking we configured the addresses wrong, it turns out we needed to twist the lens to make it focus. (duh) also camera orininally wasnt working, We forgot to tie down the pins to the breadboard when testing at first.

### AI Assistance Disclosure

This project used GenAI as an assistant for:
- Troubleshooting VGA timing and clock frequency issues in the beginning before we realized it is not possible on our monitor
- Generating initial versions of i2c_config.vhd which were then modified for RGB444 timing 
- Debugging BRAM latency compensation logic, helping fix the ofset from the bram delay
- Identifying the GRB byte ordering issue by referencing Mike Field's work
- Generating this README structure
- attempting to debug coloring issues
- research finding projects to take inspiration from and what parts of those would be useful
- Assistance with understanding the datasheet and how it can be implimented into hardware logic

All VHDL was reviewed and understood by the team. The AI was used as a
debugging and reference tool similar to Stack Overflow or a datasheet.
The project requirements, hardware connections, and design decisions were
all made by the team.

### References

- Mike Field (Hamsterworks): OV7670 Camera VHDL implementation
  http://hamsterworks.co.nz/mediawiki/index.php/OV7670_camera
- Lauri Võsandi: Piping OV7670 video to VGA output on ZYBO
  https://lauri.xn--vsandi-pxa.com/hdl/zynq/zybo-ov7670-to-vga.html
- CPE487 Lab starter code, Professor Byett, Spring 2026
  https://github.com/byett/dsd/tree/CPE487-Spring2026/Nexys-A7
- OV7670 Datasheet, Omnivision Technologies
  https://www.voti.nl/docs/OV7670.pdf
- OV7670_ArtyA7
  https://github.com/vogma/OV7670_ArtyA7/tree/main/OV7670_ArtyA7_srcs
