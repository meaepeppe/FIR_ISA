LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY adder_n IS
	GENERIC(
		Nb: INTEGER := 9
	);
	PORT(
		in_a: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		in_b: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		sum_out: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE beh_adder OF adder_n IS
	SIGNAL sum_signed: SIGNED(Nb-1 DOWNTO 0);
BEGIN
	--sum_signed <= SIGNED(in_a(Nb-1) & in_a) + SIGNED(in_b(Nb-1) & in_b);
	sum_signed <= SIGNED(in_a) + SIGNED(in_b);
	sum_out <= STD_LOGIC_VECTOR(sum_signed);
END beh_adder;
	
	
