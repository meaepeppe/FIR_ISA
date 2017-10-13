library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY mult_n IS
	GENERIC(
		N: INTEGER := 9
	);
	PORT(
		in_a: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		in_b: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		mult_out: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE beh OF mult_n IS
	SIGNAL mult_signed: SIGNED(N DOWNTO 0);
BEGIN
	mult_signed <= SIGNED(in_a) + SIGNED(in_b);
	mult_out <= STD_LOGIC_VECTOR(mult_signed);
END beh;