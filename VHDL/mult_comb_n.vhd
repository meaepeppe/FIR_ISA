LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY mult_comb_n IS
	GENERIC(
		Nb: INTEGER := 9
	);
	PORT(
		in_a: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		in_b: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		mult_out: OUT STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE beh_mult OF mult_comb_n IS
	SIGNAL mult_signed: SIGNED((2*Nb)-1 DOWNTO 0);
BEGIN
	multiplication: PROCESS(in_a, in_b)
	BEGIN
		mult_signed <= SIGNED(in_a) * SIGNED(in_b);
	END PROCESS;
	mult_out <= STD_LOGIC_VECTOR(mult_signed);
END beh_mult;
