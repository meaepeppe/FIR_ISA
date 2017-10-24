LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Cell IS 
	GENERIC(Nb:INTEGER:=9;
			Ord: INTEGER := 8); -- Filter Order
	PORT(
		CLK, RST_n, EN : IN STD_LOGIC;
		DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		SUM_IN: IN STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0);
		Bi: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		REG_OUT : OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0); 
		ADD_OUT: OUT STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0) -- aggiunti 9 bit di guardia
	);
END ENTITY;

ARCHITECTURE beh_cell OF Cell IS

	SIGNAL mult: STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	SIGNAL mult_ext: STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	SIGNAL REG_OUT_sig: STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);

	COMPONENT adder_n IS
		GENERIC(
			Nb: INTEGER := 9
		);
		PORT(
			in_a: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
			in_b: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
			sum_out: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT mult_n IS
	GENERIC(
		Nb: INTEGER := 9
	);
	PORT(
		in_a: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		in_b: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		mult_out: OUT STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0)
	);
	END COMPONENT;
	
	COMPONENT Reg_n IS
		GENERIC(Nb: INTEGER :=9);
		PORT(
			CLK, RST_n, EN: IN STD_LOGIC;
			DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
			DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
		);
	END COMPONENT; 
BEGIN
		
	Reg: Reg_n GENERIC MAP(Nb => Nb)
			   PORT MAP(DIN => DIN, CLK => CLK, RST_n => RST_n, EN => EN, DOUT => REG_OUT_sig);
	REG_OUT <= REG_OUT_sig;
	
	Product: mult_n GENERIC MAP(Nb => Nb)
					PORT MAP(in_a => REG_OUT_sig, in_b => Bi, mult_out => mult);
	
	mult_ext(Nb DOWNTO 0) <= mult (Nb+Ord DOWNTO Ord);
	mult_ext(2*Nb-1 DOWNTO Nb+1) <= (others => mult_ext(Nb));
	
	Sum: adder_n GENERIC MAP(Nb => Nb+Ord+1) -- aggiunti 9 bit di guardia
				 PORT MAP(in_a => SUM_IN, in_b => mult_ext, sum_out => ADD_OUT);
				
END beh_cell;	
