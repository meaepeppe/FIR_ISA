library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


ENTITY FIR_filter IS
GENERIC(
		N: INTEGER := 9;
		Nb: INTEGER := 9
		);
PORT(
	DIN : IN STD_LOGIC_VECTOR(Nb-1 downto 0);
	VIN:	IN STD_LOGIC;
	Bi:	IN	STD_LOGIC_VECTOR((N*Nb)-1 downto 0);
	RST_n, CLK:	IN STD_LOGIC;
	DOUT:	OUT STD_LOGIC_VECTOR(8 downto 0);
	VOUT: OUT STD_LOGIC
);
END ENTITY;

ARCHITECTURE beh OF FIR_filter IS

	COMPONENT Reg_n IS
		GENERIC(Nb: INTEGER :=9);
		PORT(
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		CLK: IN STD_LOGIC;
		DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
		);
	END COMPONENT; 
	
	BEGIN
	
END beh;