LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY camera_top IS
    PORT (
        clk_in : IN  STD_LOGIC;
        VGA_hsync : OUT STD_LOGIC;
        VGA_vsync : OUT STD_LOGIC;
        VGA_red : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        VGA_green : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        VGA_blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END camera_top;

ARCHITECTURE Behavioral OF camera_top IS

    SIGNAL pixel_clk : STD_LOGIC;
    SIGNAL pixel_row : STD_LOGIC_VECTOR(10 DOWNTO 0);
    SIGNAL pixel_col : STD_LOGIC_VECTOR(10 DOWNTO 0);
    SIGNAL red_in    : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL green_in  : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL blue_in   : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN

    clkgen : ENTITY work.clk_wiz_0
        PORT MAP (
            clk_in1  => clk_in,
            clk_out1 => pixel_clk
        );

    vgasync : ENTITY work.vga_sync
        PORT MAP (
            pixel_clk => pixel_clk,
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

    -- Color bar test pattern
   process(pixel_col, pixel_row)
    variable col : integer;
    variable row : integer;
    variable cam_col : integer;
begin
    col := to_integer(unsigned(pixel_col));
    row := to_integer(unsigned(pixel_row));

    red_in   <= "0000";
    green_in <= "0000";
    blue_in  <= "0000";

    -- centered 640x480 image inside 800x600 screen
    -- left border = 80, right border = 80
    -- top border = 60, bottom border = 60
    if (col >= 80) and (col < 720) and
       (row >= 60) and (row < 540) then

        cam_col := col - 80;

        if cam_col < 80 then
            red_in <= "1111";

        elsif cam_col < 160 then
            green_in <= "1111";

        elsif cam_col < 240 then
            blue_in <= "1111";

        elsif cam_col < 320 then
            red_in <= "1111";
            green_in <= "1111";

        elsif cam_col < 400 then
            red_in <= "1111";
            blue_in <= "1111";

        elsif cam_col < 480 then
            green_in <= "1111";
            blue_in <= "1111";

        elsif cam_col < 560 then
            red_in <= "1111";
            green_in <= "1111";
            blue_in <= "1111";

        else
            red_in <= "0000";
            green_in <= "0000";
            blue_in <= "0000";
        end if;

    end if;

end process;
END Behavioral;