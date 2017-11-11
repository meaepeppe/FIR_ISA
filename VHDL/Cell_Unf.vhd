LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Cell_Unf IS
	GENERIC
	(
		Nb: INTEGER := 9;
		Ord: INTEGER := 8
	);
	PORT
	(
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		COEFF: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		SUM_IN: IN STD_LOGIC_VECTOR(Ord+Nb DOWNTO 0);
		SUM_OUT: OUT STD_LOGIC_VECTOR(Ord+Nb DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE beh OF Cell_Unf IS

	SIGNAL mult_out, mult_ext: STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0);
	
	COMPONENT adder_n IS
	GENERIC(Nb: INTEGER := 9);
	PORT
	(
		in_a: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		in_b: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		sum_out: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
	);
	END COMPONENT;

	COMPONENT mult_n IS
	GENERIC(Nb: INTEGER := 9);
	PORT(
		in_a: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		in_b: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		mult_out: OUT STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0)
	);
	END COMPONENT;
	
BEGIN

	mult: mult_n GENERIC MAP(Nb => Nb)
	PORT MAP
	(
		in_a => DIN,
		in_b => COEFF,
		mult_out => mult_out
	);
	
	mult_ext(Nb+1 DOWNTO 0) <= mult_out(Nb+Ord DOWNTO Ord-1);
	mult_ext(Nb+Ord DOWNTO Nb+2) <= (OTHERS => mult_ext(Nb+1));
	
	sum: adder_n GENERIC MAP(Nb => Ord+Nb+1)
	PORT MAP
	(
		in_a => mult_ext,
		in_b => SUM_IN,
		sum_out => SUM_OUT
	);

END ARCHITECTURE;
