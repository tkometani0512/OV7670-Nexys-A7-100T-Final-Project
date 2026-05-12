LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ov7670_capture IS
    PORT (
        pclk : IN STD_LOGIC; -- detailed description of function of each pin is in the top file. That describes how they are coded to function in this program.
        vsync : IN STD_LOGIC;
        href : IN STD_LOGIC;
        d : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        
        addr : OUT STD_LOGIC_VECTOR(16 DOWNTO 0); -- This is the memory address. This indictes the location in memory where the current pixel should be stored. Since the image is 320 x 240 QVGA has 76,800 pixels, I used a 17 bit vector because it is the smallest power of two. 2^17 = 131,072.
        dout : OUT STD_LOGIC_VECTOR(11 DOWNTO 0); -- dout carries the color information of the pixel being captured. This has yet to be formatted in a configuration file for i2c/sccb but it is currently in RGB444 format. 4 bits of each. There are other formats but I felt like 444 would be simple since each color would get the same amount of bits. May change later once I write the configuration file if it gives me trouble.
        we : OUT STD_LOGIC -- write enable port tells the memory when to save the data appearing on addr and dout.
    );
END ov7670_capture;

ARCHITECTURE Behavioral OF ov7670_capture IS

    TYPE state_type IS (WAIT_VSYNC, WAIT_HREF, CAPTURE);
    SIGNAL state : state_type := WAIT_VSYNC;
    
    SIGNAL row : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL col : UNSIGNED(8 DOWNTO 0) := (OTHERS => '0');
    SIGNAL byte_sel : STD_LOGIC := '0';
    SIGNAL hi_byte : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

BEGIN

    PROCESS(pclk)
    BEGIN
        IF rising_edge(pclk) THEN
            we <= '0';

            CASE state IS

                WHEN WAIT_VSYNC =>
                    IF vsync = '1' THEN
                        row <= (OTHERS => '0');
                        col <= (OTHERS => '0');
                        byte_sel <= '0';
                        state <= WAIT_HREF;
                    END IF;

                WHEN WAIT_HREF =>
                    IF row >= 240 THEN
                        state <= WAIT_VSYNC;
                    ELSIF href = '1' THEN
                        col <= (OTHERS => '0');
                        byte_sel <= '0';
                        state <= CAPTURE;
                    END IF;

                WHEN CAPTURE =>
                    IF href = '0' THEN
                        row <= row + 1;
                        state <= WAIT_HREF;
                    ELSE
                        IF byte_sel = '0' THEN
                            -- First byte: XXXX RRRR, the first four get ignored.
                            hi_byte  <= d;
                            byte_sel <= '1';
                        ELSE
                            -- Second byte: GGGG BBBB. This is where we have encountered the most trouble. There is currently an issue where red objects and green objects can be seen as whatever color they are set at here howeber blue is always grey which means that the information is being lost somewhere or that all color information is sent simultaneously meaning that it turns out grey. 
                            -- This was changed from before because the previous code, when used caused the screen to be neon and the colors to be constantly changing even when the video worked meaning the color data was mixed up. problem causing the neon was because I was trying to send 565 format to 12 bits. I thought that 12 bits would automatically work with 444 format.
                            dout <= d(3 downto 0) & hi_byte(3 downto 0) & d(7 downto 4);
                                
                            IF col < 320 AND row < 240 THEN
                                addr <= STD_LOGIC_VECTOR(
                                    to_unsigned(
                                        to_integer(row) * 320 + to_integer(col),
                                        17));
                                we <= '1';
                            END IF;

                            col <= col + 1;
                            byte_sel <= '0';
                        END IF;
                    END IF;
            END CASE;
        END IF;
    END PROCESS;

END Behavioral;