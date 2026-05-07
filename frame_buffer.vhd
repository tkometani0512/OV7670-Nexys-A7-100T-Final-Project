LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY frame_buffer IS
    PORT (
        clk_a : IN  STD_LOGIC;
        we_a : IN  STD_LOGIC;
        addr_a : IN  STD_LOGIC_VECTOR(16 DOWNTO 0);
        din_a : IN  STD_LOGIC_VECTOR(11 DOWNTO 0);

        clk_b : IN  STD_LOGIC;
        addr_b : IN  STD_LOGIC_VECTOR(16 DOWNTO 0);
        dout_b : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    );
END frame_buffer;

ARCHITECTURE Behavioral OF frame_buffer IS

    TYPE ram_type IS ARRAY(0 TO 76799) OF STD_LOGIC_VECTOR(11 DOWNTO 0);
    SHARED VARIABLE ram : ram_type := (OTHERS => X"F00");

BEGIN

    PROCESS(clk_a)
    BEGIN
        IF rising_edge(clk_a) THEN
            IF we_a = '1' THEN
                ram(to_integer(unsigned(addr_a))) := din_a;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(clk_b)
    BEGIN
        IF rising_edge(clk_b) THEN
            dout_b <= ram(to_integer(unsigned(addr_b)));
        END IF;
    END PROCESS;

END Behavioral;