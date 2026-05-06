library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity camera_top is
    port (
        clk_100 : in std_logic;

        -- VGA outputs
        vga_r  : out std_logic_vector(3 downto 0);
        vga_g  : out std_logic_vector(3 downto 0);
        vga_b  : out std_logic_vector(3 downto 0);
        vga_hs : out std_logic;
        vga_vs : out std_logic;

        -- Camera pins kept here only so your XDC does not complain
        cam_xclk  : out std_logic;
        cam_pclk  : in  std_logic;
        cam_vsync : in  std_logic;
        cam_href  : in  std_logic;
        cam_d     : in  std_logic_vector(7 downto 0);
        cam_sioc  : out std_logic;
        cam_siod  : inout std_logic
    );
end camera_top;

architecture Behavioral of camera_top is

    signal clk_25    : std_logic;

    signal pixel_row : std_logic_vector(10 downto 0);
    signal pixel_col : std_logic_vector(10 downto 0);

    signal red_in    : std_logic_vector(3 downto 0);
    signal green_in  : std_logic_vector(3 downto 0);
    signal blue_in   : std_logic_vector(3 downto 0);

begin

    -- Your class clock wizard: 100 MHz in, 25 MHz out
    clk_inst : entity work.clk_wiz_0
        port map (
            clk_in1  => clk_100,
            clk_out1 => clk_25
        );

    -- Temporarily send 25 MHz to camera XCLK too
    cam_xclk <= clk_25;

    -- Camera config disabled for VGA-only test
    cam_sioc <= '1';
    cam_siod <= 'Z';

    -- VGA sync module
    vga_inst : entity work.vga_sync
        port map (
            pixel_clk => clk_25,

            red_in    => red_in,
            green_in  => green_in,
            blue_in   => blue_in,

            red_out   => vga_r,
            green_out => vga_g,
            blue_out  => vga_b,

            hsync     => vga_hs,
            vsync     => vga_vs,

            pixel_row => pixel_row,
            pixel_col => pixel_col
        );

    -- VGA test pattern: vertical color bars
    process(pixel_col, pixel_row)
        variable x : integer;
        variable y : integer;
    begin
        x := to_integer(unsigned(pixel_col));
        y := to_integer(unsigned(pixel_row));

        if x < 80 then
            red_in   <= "1111";
            green_in <= "0000";
            blue_in  <= "0000";

        elsif x < 160 then
            red_in   <= "0000";
            green_in <= "1111";
            blue_in  <= "0000";

        elsif x < 240 then
            red_in   <= "0000";
            green_in <= "0000";
            blue_in  <= "1111";

        elsif x < 320 then
            red_in   <= "1111";
            green_in <= "1111";
            blue_in  <= "0000";

        elsif x < 400 then
            red_in   <= "1111";
            green_in <= "0000";
            blue_in  <= "1111";

        elsif x < 480 then
            red_in   <= "0000";
            green_in <= "1111";
            blue_in  <= "1111";

        elsif x < 560 then
            red_in   <= "1111";
            green_in <= "1111";
            blue_in  <= "1111";

        else
            red_in   <= "0000";
            green_in <= "0000";
            blue_in  <= "0000";
        end if;
    end process;

end Behavioral;