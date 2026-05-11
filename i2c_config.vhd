LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- A lot of other projects used IP catalog for I2C. 
ENTITY i2c_config IS
    PORT (
        clk : IN STD_LOGIC;
        sioc : OUT STD_LOGIC;
        siod : INOUT STD_LOGIC;
        done : OUT STD_LOGIC
    );
END i2c_config;

ARCHITECTURE Behavioral OF i2c_config IS

    CONSTANT DIVIDER : INTEGER := 250; -- for 25 MHz clk
    CONSTANT Q : INTEGER := DIVIDER / 4;
    CONSTANT CAM_ADDR : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"42";

    TYPE config_pair IS RECORD
        reg : STD_LOGIC_VECTOR(7 DOWNTO 0);
        val : STD_LOGIC_VECTOR(7 DOWNTO 0);
    END RECORD;
    TYPE config_array IS ARRAY(NATURAL RANGE <>) OF config_pair;

    CONSTANT configs : config_array := (
        (X"12", X"80"),  
        (X"13", X"00"), 
        (X"40", X"D0"),  
        (X"8C", X"02"),  
        (X"12", X"14"),  
        (X"40", X"B0"),  
        (X"8C", X"02"),  
        (X"11", X"01"),  
        (X"32", X"80"),  
        (X"17", X"16"),  
        (X"18", X"04"), 
        (X"19", X"02"), 
        (X"1A", X"7A"),  
        (X"03", X"0A"), 
        (X"70", X"3A"),  
        (X"71", X"35"),  
        (X"72", X"11"),  
        (X"73", X"F0"),  
        (X"A2", X"02"),  
        (X"4F", X"80"),  
        (X"50", X"80"),
        (X"51", X"00"),
        (X"52", X"22"),
        (X"53", X"5E"),
        (X"54", X"80"),
        (X"58", X"9E"),
        (X"43", X"0A"), 
        (X"44", X"F0"),
        (X"45", X"34"),
        (X"46", X"58"),
        (X"47", X"28"),
        (X"48", X"3A"),
        (X"59", X"88"),
        (X"5A", X"88"),
        (X"5B", X"44"),
        (X"5C", X"67"),
        (X"5D", X"49"),
        (X"5E", X"0E"),
        (X"6C", X"0A"),
        (X"6D", X"55"),
        (X"6E", X"11"),
        (X"6F", X"9F"),
        (X"6A", X"40"),
        (X"01", X"40"),
        (X"02", X"40"),
        (X"13", X"E7"),  
        (X"7A", X"20"),  
        (X"7B", X"10"),
        (X"7C", X"1E"),
        (X"7D", X"35"),
        (X"7E", X"5A"),
        (X"7F", X"69"),
        (X"80", X"76"),
        (X"81", X"80"),
        (X"82", X"88"),
        (X"83", X"8F"),
        (X"84", X"96"),
        (X"85", X"A3"),
        (X"86", X"AF"),
        (X"87", X"C4"),
        (X"88", X"D7"),
        (X"89", X"E8"),
        (X"13", X"E7"),  
        (X"00", X"00"),
        (X"10", X"00"),
        (X"0D", X"40"),
        (X"14", X"18"),
        (X"A5", X"05"),
        (X"AB", X"07"),
        (X"24", X"95"),
        (X"25", X"33"),
        (X"26", X"E3"),
        (X"9F", X"78"),
        (X"A0", X"68"),
        (X"A1", X"03"),
        (X"A6", X"D8"),
        (X"A7", X"D8"),
        (X"A8", X"F0"),
        (X"A9", X"90"),
        (X"AA", X"94"),
        (X"13", X"E5"),
        (X"40", X"B0"),  
        (X"8C", X"02")  
    );

    CONSTANT NUM_REGS : INTEGER := configs'LENGTH;

    TYPE i2c_state_type IS (
        IDLE, START, SEND_BYTE, ACK, STOP1, PAUSE, FINISHED
    );

    SIGNAL state : i2c_state_type := IDLE;
    SIGNAL reg_idx : INTEGER RANGE 0 TO NUM_REGS := 0;
    SIGNAL bit_cnt : INTEGER RANGE 0 TO 7 := 7;
    SIGNAL clk_cnt : INTEGER RANGE 0 TO DIVIDER-1 := 0;
    SIGNAL byte_cnt : INTEGER RANGE 0 TO 2 := 0;
    SIGNAL shift_reg : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL scl_int : STD_LOGIC := '1';
    SIGNAL sda_int : STD_LOGIC := '1';
    SIGNAL pause_cnt : INTEGER RANGE 0 TO 1250000 := 0;
    SIGNAL is_reset : STD_LOGIC := '0';

BEGIN

    sioc <= scl_int;
    siod <= '0' WHEN sda_int = '0' ELSE 'Z';
    done <= '1' WHEN state = FINISHED ELSE '0';

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN

            CASE state IS

                WHEN IDLE =>
                    scl_int <= '1';
                    sda_int <= '1';
                    clk_cnt <= 0;
                    IF reg_idx < NUM_REGS THEN
                        shift_reg <= CAM_ADDR;
                        byte_cnt <= 0;
                        bit_cnt <= 7;
                        state <= START;
                    ELSE
                        state <= FINISHED;
                    END IF;

                WHEN START =>
                    clk_cnt <= clk_cnt + 1;
                    CASE clk_cnt IS
                        WHEN 0 => sda_int <= '1'; scl_int <= '1';
                        WHEN Q => sda_int <= '0';
                        WHEN Q*2 => scl_int <= '0';
                        WHEN Q*3 =>
                            clk_cnt <= 0;
                            state <= SEND_BYTE;
                        WHEN OTHERS => NULL;
                    END CASE;

                WHEN SEND_BYTE =>
                    clk_cnt <= clk_cnt + 1;
                    CASE clk_cnt IS
                        WHEN 0 =>
                            scl_int <= '0';
                            sda_int <= shift_reg(bit_cnt);
                        WHEN Q => scl_int <= '1';
                        WHEN Q*3 =>
                            IF bit_cnt = 0 THEN
                                clk_cnt <= 0;
                                state <= ACK;
                            ELSE
                                bit_cnt <= bit_cnt - 1;
                                clk_cnt <= 0;
                            END IF;
                        WHEN OTHERS => NULL;
                    END CASE;

                WHEN ACK =>
                    clk_cnt <= clk_cnt + 1;
                    CASE clk_cnt IS
                        WHEN 0 => scl_int <= '0'; sda_int <= '1';
                        WHEN Q => scl_int <= '1';
                        WHEN Q*3 =>
                            scl_int <= '0';
                            clk_cnt <= 0;
                            bit_cnt <= 7;
                            IF byte_cnt = 0 THEN
                                shift_reg <= configs(reg_idx).reg;
                                byte_cnt <= 1;
                                state <= SEND_BYTE;
                            ELSIF byte_cnt = 1 THEN
                                shift_reg <= configs(reg_idx).val;
                                byte_cnt <= 2;
                                state <= SEND_BYTE;
                            ELSE
                                state <= STOP1;
                            END IF;
                        WHEN OTHERS => NULL;
                    END CASE;

                WHEN STOP1 =>
                    clk_cnt <= clk_cnt + 1;
                    CASE clk_cnt IS
                        WHEN 0 => scl_int <= '0'; sda_int <= '0';
                        WHEN Q => scl_int <= '1';
                        WHEN Q*2 => sda_int <= '1';
                        WHEN Q*3 =>
                            clk_cnt <= 0;
                            pause_cnt <= 0;
                            -- Long pause after reset register only
                            IF reg_idx = 0 THEN
                                is_reset <= '1';
                            ELSE
                                is_reset <= '0';
                            END IF;
                            reg_idx <= reg_idx + 1;
                            state <= PAUSE;
                        WHEN OTHERS => NULL;
                    END CASE;

                WHEN PAUSE =>
                    pause_cnt <= pause_cnt + 1;
                    IF is_reset = '1' THEN
                        -- 10ms pause after reset at 25MHz
                        IF pause_cnt = 250000 THEN
                            state <= IDLE;
                        END IF;
                    ELSE
                        -- 1ms pause between other registers
                        IF pause_cnt = 25000 THEN
                            state <= IDLE;
                        END IF;
                    END IF;

                WHEN FINISHED =>
                    scl_int <= '1';
                    sda_int <= '1';

            END CASE;
        END IF;
    END PROCESS;

END Behavioral;