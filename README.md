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
| sw_freeze | L16 (SW1) | Slide up to freeze current frame |
| sw_invert | J15 (SW0) | Slide up to enable color invert filter |

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

OV7670        Nexys A7  
───────        ────────  
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

