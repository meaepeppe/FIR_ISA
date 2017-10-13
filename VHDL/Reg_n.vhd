library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY Reg_n IS
GENERIC(Nb: INTEGER :=9);
PORT(
	DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	CLK: IN STD_LOGIC;
	DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
);
END ENTITY; 

ARCHITECTURE beh OF Reg_n IS 
	
BEGIN
	PROCESS(CLK)
	BEGIN
		IF CLK'EVENT AND CLK = '1' THEN
		DOUT <= DIN;
		END IF;
	END PROCESS;
END beh;