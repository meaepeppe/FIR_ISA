library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY Cnt_n IS
	GENERIC(N: INTEGER := 4);
	PORT(
		CLK, RST_n, EN, LD: STD_LOGIC;
		DIN: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		DOUT: BUFFER STD_LOGIC_VECTOR(N-1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE beh OF Cnt_n IS
BEGIN
	Counter: PROCESS(CLK)
	BEGIN
		IF CLK'EVENT AND CLK = '1' THEN
			IF RST_n = '0' THEN
				DOUT <= (OTHERS => '0');
			ELSIF EN = '1' THEN
				IF LD = '1' THEN
					DOUT <= DIN;
				ELSE
					DOUT <= STD_LOGIC_VECTOR(SIGNED(DOUT) + 1);
				END IF;
			END IF;		
		END IF;
	END PROCESS;
END beh;