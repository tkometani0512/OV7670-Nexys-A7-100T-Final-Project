LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Top file basically connects everything together while also covering anything that could cause a problem. It crops the image out/frames it. It also compensates for on board bram timing problems. Also initializies the I2C configuration for camera to work correctly 
ENTITY camera_top IS
    PORT (
        clk_in : IN    STD_LOGIC;
        cam_xclk : OUT STD_LOGIC; -- as stated before and many times in the project, this xclk is the input clock to tell the camera when to be working. It requires a frequency of 24 MHz, it worked with 25 but still I prefer being as close as possible since the timing on the vga and the camera are both relatively strict so it couldnt hurt in case it causes and dropping of the data or anything like that.
        cam_pclk : IN  STD_LOGIC; -- Pclk tells the FPGA when the data from pins d0 - d7 are ready to read and stable. Every pulse of pclk pushes out one byte of data from the camera. Reading d0 - d7 must be percisely timed with pclk or else you get garbage noise.
        cam_vsync : IN  STD_LOGIC; -- Vsync is related to the frames specifically. It signals to the FPGA when to prepare for a new set of image data. So it is coded to wait for a vsync pulse to start the capture process. Waiting for vsync to go high indicates the end of a previous frame. waiting for vsync to go low, some datasheets say that the falling edge is the go signal to begin reading the individual lines (Href, of the new frame. Vsync reads the data until the next vsync pulse which signals an entire frame completion 
        cam_href : IN  STD_LOGIC; --Corresponds to href pin. Its job is to tell the FPGA exactly when a row of pixels is being sent. When href is high, the camera is transmitting active pixel data for a specific horizontal line. When href is high the FPGA should look at the PCLK to know when to grab each byte from the data pins. So FPGA knows where one line ends and the next begins otherwise it would grab continuous data and the final image would be shifted or it wouldnt be coherent images
        cam_d : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); -- Represent 8 pins d0 -  d7 which are in charge of color data from the camera. After some research it turns out that there are different color formats you can configure the camera to which determines what color each pin actually corresponds to. There is configurations such as RGB565, and yuv/ycbcr 4:2:2 which can be configured in the SCCB/I2C interface which I have to set up as the next step
        cam_sioc : OUT   STD_LOGIC; -- This is for I2c/SCCB (serial camera control bus) connection. SIOC is the clock signal to the camera which sets the pace of data transfer.
        cam_siod : INOUT STD_LOGIC; -- This is the data line where theh setting like brightness, contrast, and color format (RGB444 in our case) is sent.
        VGA_hsync : OUT   STD_LOGIC;
        VGA_vsync : OUT   STD_LOGIC;
        VGA_red : OUT   STD_LOGIC_VECTOR(3 DOWNTO 0);
        VGA_green : OUT   STD_LOGIC_VECTOR(3 DOWNTO 0);
        VGA_blue : OUT   STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END camera_top;

ARCHITECTURE Behavioral OF camera_top IS

    SIGNAL clk_50 : STD_LOGIC; -- for VGA clk timing 
    SIGNAL clk_25 : STD_LOGIC; -- for CAMERA clk timing 
    SIGNAL pixel_row : STD_LOGIC_VECTOR(10 DOWNTO 0); --VGA
    SIGNAL pixel_col : STD_LOGIC_VECTOR(10 DOWNTO 0); --VGA
    SIGNAL red_in : STD_LOGIC_VECTOR(3 DOWNTO 0); --VGA
    SIGNAL green_in : STD_LOGIC_VECTOR(3 DOWNTO 0); --VGA
    SIGNAL blue_in : STD_LOGIC_VECTOR(3 DOWNTO 0); --VGA
    
    -- Frame buffer signals
    SIGNAL fb_we_a : STD_LOGIC;
    SIGNAL fb_addr_a : STD_LOGIC_VECTOR(16 DOWNTO 0);
    SIGNAL fb_din_a : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL fb_addr_b : STD_LOGIC_VECTOR(16 DOWNTO 0) := (OTHERS => '0');
    SIGNAL fb_dout : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL in_frame : STD_LOGIC := '0';
    SIGNAL config_done : STD_LOGIC;

BEGIN

    clkgen : ENTITY work.clk_wiz_0
        PORT MAP (
            clk_in1 => clk_in,
            clk_out1 => clk_50,
            clk_out2 => clk_25
        );

    cam_xclk <= clk_25;

    -- I2C configuration runs once at startup
    i2c_cfg : ENTITY work.i2c_config
        PORT MAP (
            clk => clk_25,
            sioc => cam_sioc,
            siod => cam_siod,
            done => config_done
        );

    vgasync : ENTITY work.vga_sync
        PORT MAP (
            pixel_clk => clk_50,
            red_in => red_in,
            green_in => green_in,
            blue_in => blue_in,
            red_out => VGA_red,
            green_out => VGA_green,
            blue_out => VGA_blue,
            hsync => VGA_hsync,
            vsync => VGA_vsync,
            pixel_row => pixel_row,
            pixel_col => pixel_col
        );

    fb : ENTITY work.frame_buffer
        PORT MAP (
            clk_a => cam_pclk,
            we_a => fb_we_a,
            addr_a => fb_addr_a,
            din_a => fb_din_a,
            clk_b => clk_50,
            addr_b => fb_addr_b,
            dout_b => fb_dout
        );

    capture : ENTITY work.ov7670_capture
        PORT MAP (
            pclk => cam_pclk,
            vsync => cam_vsync,
            href => cam_href,
            d => cam_d,
            addr => fb_addr_a,
            dout => fb_din_a,
            we => fb_we_a
        );

    -- Color output: BRAM data inside frame, black outside
    red_in <= fb_dout(11 DOWNTO 8) WHEN in_frame = '1' ELSE "0000";
    green_in <= fb_dout(7  DOWNTO 4) WHEN in_frame = '1' ELSE "0000";
    blue_in <= fb_dout(3  DOWNTO 0) WHEN in_frame = '1' ELSE "0000";


    -- Clocked address calculation compensating for BRAM latency. I was having trouble with timing. I researched and apparently I needed to compensate for the latency of BRAM because otherwise the signal would be wrong. The BRAM would be too behind for meaningful data transfer.
    PROCESS(clk_50)
        VARIABLE col : INTEGER;
        VARIABLE row : INTEGER;
        VARIABLE cam_col : INTEGER;
        VARIABLE cam_row : INTEGER;
        VARIABLE addr : INTEGER;
    BEGIN
        IF rising_edge(clk_50) THEN
            col := to_integer(unsigned(pixel_col));
            row := to_integer(unsigned(pixel_row));

            IF col >= 80 AND col < 720 AND
               row >= 60 AND row < 540 THEN
                cam_col := (col - 80) / 2;
                cam_row := (row - 60) / 2;
                addr := cam_row * 320 + cam_col;
                fb_addr_b <= STD_LOGIC_VECTOR(to_unsigned(addr, 17));
                in_frame <= '1';
            ELSE
                fb_addr_b <= (OTHERS => '0');
                in_frame <= '0';
            END IF;
        END IF;
    END PROCESS;

END Behavioral;