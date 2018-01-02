LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.math_real.all;
USE work.FIR_constants.all;

ENTITY Cell_Pipe IS 
	PORT(
		CLK, RST_n, EN : IN STD_LOGIC;
		DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		SUM_IN: IN STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);
		Bi: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		REG_OUT : BUFFER STD_LOGIC_VECTOR(Nb-1 DOWNTO 0); 
		ADD_OUT: OUT STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0) 
	);
END ENTITY;

ARCHITECTURE beh OF Cell_Pipe IS
	
	SIGNAL mult : STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	SIGNAL mult_ext, Last_reg_out, Sum_in_reg : STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);
	SIGNAL Reg_buf: STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);

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
			   PORT MAP(DIN => DIN, CLK => CLK, RST_n => RST_n, EN => EN, DOUT => Reg_buf);
	
	REG_OUT <= Reg_buf;

	Product: mult_n GENERIC MAP(Nb => Nb)
					PORT MAP(in_a => Reg_buf, in_b => Bi, mult_out => mult);
					
	mult_extension_0: IF (Nbadder <= Nbmult) GENERATE
			mult_ext <= mult ((mult'LENGTH - (Nbmult - Nbadder) -1) DOWNTO (mult'LENGTH)-1-(Nbmult-1));
		END GENERATE;
		
	mult_extension_1: IF (Nbadder > Nbmult) GENERATE
			mult_ext(Nbmult-1 DOWNTO 0) <= mult((mult'LENGTH-1) DOWNTO (mult'LENGTH-1)-(Nbmult-1));
			mult_ext(Nbadder-1 DOWNTO Nbmult) <= (OTHERS => (mult_ext(Nbmult-1)));
		END GENERATE;
		
	Mult_Pipe_reg: Reg_n GENERIC MAP(Nb => mult_ext'LENGTH)
				PORT MAP(DIN => mult_ext, CLK => CLK, RST_n => RST_n, EN => EN, DOUT => Last_reg_out);
	
	Sum_Pipe_reg: Reg_n GENERIC MAP(Nb => SUM_IN'LENGTH)
				   PORT MAP(CLK => CLK, RST_n => RST_n, EN => EN,
							DIN => SUM_IN,
							DOUT => Sum_in_reg);
	
	Sum: adder_n GENERIC MAP(Nb => Sum_in_reg'LENGTH)
				 PORT MAP(in_a => Sum_in_reg, in_b => Last_reg_out, sum_out => ADD_OUT);
				
END beh;	