LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY camera_top IS
    PORT (
        clk_in : IN  STD_LOGIC;
        cam_xclk : OUT STD_LOGIC;
        VGA_hsync : OUT STD_LOGIC;
        VGA_vsync : OUT STD_LOGIC;
        VGA_red : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        VGA_green : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        VGA_blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END camera_top;

ARCHITECTURE Behavioral OF camera_top IS

    SIGNAL clk_50 : STD_LOGIC;
    SIGNAL clk_25 : STD_LOGIC;
    SIGNAL pixel_row : STD_LOGIC_VECTOR(10 DOWNTO 0);
    SIGNAL pixel_col : STD_LOGIC_VECTOR(10 DOWNTO 0);
    SIGNAL red_in : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL green_in : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL blue_in : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- Frame buffer signals
    SIGNAL fb_we_a : STD_LOGIC := '0';
    SIGNAL fb_addr_a : STD_LOGIC_VECTOR(16 DOWNTO 0) := (OTHERS => '0');
    SIGNAL fb_din_a : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL fb_addr_b : STD_LOGIC_VECTOR(16 DOWNTO 0) := (OTHERS => '0');
    SIGNAL fb_dout : STD_LOGIC_VECTOR(11 DOWNTO 0);

    -- Registered signal to track whether current pixel is in camera area
    -- This is delayed by 1 cycle to match BRAM read latency
    SIGNAL in_frame : STD_LOGIC := '0';

BEGIN

    clkgen : ENTITY work.clk_wiz_0  
        PORT MAP (
            clk_in1 => clk_in,
            clk_out1 => clk_50,
            clk_out2 => clk_25
        );

    cam_xclk <= clk_25; -- sets xclk to 25 like needed when camera is attached

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
            clk_a => clk_25,
            we_a => fb_we_a,
            addr_a => fb_addr_a,
            din_a => fb_din_a,
            clk_b => clk_50,
            addr_b => fb_addr_b,
            dout_b => fb_dout
        );

    -- Connect BRAM output to color signals only when in_frame is high
    -- in_frame is registered so it arrives at the same time as BRAM data
    red_in   <= fb_dout(11 DOWNTO 8) WHEN in_frame = '1' ELSE "0000";
    green_in <= fb_dout(7  DOWNTO 4) WHEN in_frame = '1' ELSE "0000";
    blue_in  <= fb_dout(3  DOWNTO 0) WHEN in_frame = '1' ELSE "0000";

    -- Clocked process: calculate address and register in_frame
    -- Everything here is one cycle ahead of when vga_sync displays it
    -- This compensates for the 1 cycle BRAM read latency
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