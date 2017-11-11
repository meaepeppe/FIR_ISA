LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Cell_Pipe IS 
	GENERIC(Nb:INTEGER:=9;
			Ord: INTEGER := 8); 
	PORT(
		CLK, RST_n, EN_1, EN_2 : IN STD_LOGIC;
		DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		SUM_IN: IN STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0);
		Bi: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		REG_OUT : BUFFER STD_LOGIC_VECTOR(Nb-1 DOWNTO 0); 
		ADD_OUT: OUT STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0) 
	);
END ENTITY;

ARCHITECTURE beh OF Cell_Pipe IS

	SIGNAL mult, Last_reg_out, Last_reg_ext, Sum_in_reg: STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
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
			   PORT MAP(DIN => DIN, CLK => CLK, RST_n => RST_n, EN => EN_1, DOUT => Reg_buf);
	
	REG_OUT <= Reg_buf;

	Product: mult_n GENERIC MAP(Nb => Nb)
					PORT MAP(in_a => Reg_buf, in_b => Bi, mult_out => mult);
					
	Mult_Pipe_reg: Reg_n GENERIC MAP(Nb => mult'LENGTH)
				PORT MAP(DIN => mult, CLK => CLK, RST_n => RST_n, EN => EN_2, DOUT => Last_reg_out);
	
	Last_reg_ext(Nb+1 DOWNTO 0) <= Last_reg_out(Nb+Ord DOWNTO Ord-1);
	Last_reg_ext(Nb+Ord DOWNTO Nb+2) <= (OTHERS => (Last_reg_ext(Nb+1)));
	
	Sum_Pipe_reg: Reg_n GENERIC MAP(Nb => SUM_IN'LENGTH)
				   PORT MAP(CLK => CLK, RST_n => RST_n, EN => EN_1,
							DIN => SUM_IN,
							DOUT => Sum_in_reg);
	
	Sum: adder_n GENERIC MAP(Nb => Nb+Ord+1)
				 PORT MAP(in_a => Sum_in_reg, in_b => Last_reg_ext, sum_out => ADD_OUT);
				
END beh;	