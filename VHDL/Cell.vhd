library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY Cell IS 
	GENERIC(Nb:INTEGER:=9);
	PORT(
		DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		SUM_IN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		coeff: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		REG_OUT : OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		SUM_OUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	);
END ENTITY;

ARCHITECTURE beh OF Cell IS

BEGIN
	
END beh;	