# OV7670-Nexys-A7-100T-Final-Project

## Project Description

This project captures live video from an OV7670 camera module and displays it
on a VGA monitor using a Nexys A7 100T FPGA board. The camera feed is captured
in real time, stored in a Block RAM frame buffer, and displayed centered within
an 800×600 VGA output. The 320×240 captured image is scaled 2×2 per pixel to
fill a 640×480 area centered on screen with black borders on all sides.

The system operates entirely in hardware with no processor — all pixel capture,
buffering, and display logic is implemented in VHDL running on the FPGA fabric.

Two user controls are provided via onboard switches: a freeze frame switch that
holds the current frame on screen indefinitely, and a color invert filter that
produces a real time color negative effect.

---

## System Block Diagram
<img width="1101" height="850" alt="OV7670_block_diagram" src="https://github.com/user-attachments/assets/40db3287-fbf8-4b59-9c41-5da1e52b8ed1" />
