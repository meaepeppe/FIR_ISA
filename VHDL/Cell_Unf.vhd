LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.math_real.all;
USE work.FIR_constants.all;

ENTITY Cell_Unf IS
	GENERIC
	(
		Nb: INTEGER := NUM_BITS; --9
		Ord: INTEGER := FIR_ORDER; --8
		Nbmult: INTEGER := NUM_BITS_MULT --10
	);
	PORT
	(
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		COEFF: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		SUM_IN: IN STD_LOGIC_VECTOR(NBADDER-1 DOWNTO 0);
		SUM_OUT: OUT STD_LOGIC_VECTOR(NBADDER-1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE beh OF Cell_Unf IS
	
	SIGNAL mult_out: STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	SIGNAL mult_ext: STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);
	
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
	
	mult_ext(Nbmult-1 DOWNTO 0) <= mult_out((mult_out'LENGTH-1) DOWNTO (mult_out'LENGTH-1)-(Nbmult-1));
	mult_ext(Nbadder-1 DOWNTO Nbmult) <= (OTHERS => mult_ext(Nbmult-1));
	
	sum: adder_n GENERIC MAP(Nb => Nbadder)
	PORT MAP
	(
		in_a => mult_ext,
		in_b => SUM_IN,
		sum_out => SUM_OUT
	);

END ARCHITECTURE;
