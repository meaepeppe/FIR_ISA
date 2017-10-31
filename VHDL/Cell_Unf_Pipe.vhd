LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Cell_Unf_Pipe IS
	GENERIC
	(
		Nb: INTEGER := 9;
		Ord: INTEGER := 8
	);
	PORT
	(
		CLK, RST_n, EN_1, EN_2: IN STD_LOGIC;
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		COEFF: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		SUM_IN: IN STD_LOGIC_VECTOR(Ord+Nb DOWNTO 0);
		SUM_OUT: OUT STD_LOGIC_VECTOR(Ord+Nb DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE beh OF Cell_Unf_Pipe IS
	
	SIGNAL mult_out, mult_reg_out, mult_ext, Sum_reg_out: STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0);
	
	COMPONENT Reg_n IS
	GENERIC(Nb: INTEGER :=9);
	PORT(
		CLK, RST_n, EN: IN STD_LOGIC;
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
	);
	END COMPONENT; 
	
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
	
	mult_reg: Reg_n GENERIC MAP(Nb => mult_out'LENGTH)
				PORT MAP(CLK => CLK, RST_n => RST_n, EN => EN_2,
						DIN => mult_out,
						DOUT => mult_reg_out);
	
	mult_ext(Nb DOWNTO 0) <= mult_reg_out(Nb+Ord DOWNTO Ord);
	mult_ext(Nb+Ord DOWNTO Nb+1) <= (OTHERS => mult_ext(Nb));
	
	sum_reg: Reg_n GENERIC MAP(Nb => SUM_IN'LENGTH)
					PORT MAP (CLK => CLK, RST_n => RST_n, EN => EN_1,
							  DIN => SUM_IN,
							  DOUT => Sum_reg_out);
	
	sum: adder_n GENERIC MAP(Nb => Ord+Nb+1)
	PORT MAP
	(
		in_a => mult_ext,
		in_b => Sum_reg_out,
		sum_out => SUM_OUT
	);
	
END ARCHITECTURE;
