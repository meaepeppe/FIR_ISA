library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY adder_n IS
	GENERIC(
		N: INTEGER := 9
	);
	PORT(
		in_a: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		in_b: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		sum_out: OUT STD_LOGIC_VECTOR(N DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE beh OF adder_n IS
	SIGNAL sum_signed: SIGNED(N DOWNTO 0);
BEGIN
	sum_signed <= SIGNED(in_a(N-1) & in_a) + SIGNED(in_b(N-1) & in_b);
	sum_out <= STD_LOGIC_VECTOR(sum_signed);
END beh;
	
	