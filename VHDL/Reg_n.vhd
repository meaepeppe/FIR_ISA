LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Reg_n IS
GENERIC(Nb: INTEGER :=9);
PORT(
	CLK, RST_n, EN: IN STD_LOGIC;
	DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
);
END ENTITY; 

ARCHITECTURE beh_reg OF Reg_n IS 
	
BEGIN
	PROCESS(CLK)
	BEGIN
		IF CLK'EVENT AND CLK = '1' THEN
			IF RST_n = '0' THEN
				DOUT <= (OTHERS => '0');
			ELSIF EN = '1' THEN
				DOUT <= DIN;
			END IF;
		END IF;
	END PROCESS;
END beh_reg;
