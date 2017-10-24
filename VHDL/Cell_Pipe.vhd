LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Cell_Pipe IS 
	GENERIC(Nb:INTEGER:=9;
			Ord: INTEGER := 8;
			NRegs: INTEGER := 1); -- Num of Pipeline Registers
	PORT(
		CLK, RST_n, EN : IN STD_LOGIC;
		DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		SUM_IN: IN STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0);
		Bi: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		REG_OUT : BUFFER STD_LOGIC_VECTOR(Nb-1 DOWNTO 0); 
		ADD_OUT: OUT STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0) 
	);
END ENTITY;

ARCHITECTURE beh OF Cell_Pipe IS

	TYPE Reg_sig_array IS ARRAY (NRegs-1 DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	SIGNAL Regs_pipe_out: Reg_sig_array;
	
	SIGNAL mult, Last_reg_out, Last_reg_ext: STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
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
	Regs_pipe_out(0) <= Reg_buf;
	
	Pipe_Reg_gen: FOR i IN 0 TO (NRegs-2) GENERATE
		Single_Reg_gen: Reg_n GENERIC MAP(Nb => Nb)
		PORT MAP(CLK => CLK, RST_n => RST_n, EN => EN,
		DIN => Regs_pipe_out(i),
		DOUT => Regs_pipe_out(i+1)
		);
	END GENERATE;

	Product: mult_n GENERIC MAP(Nb => Nb)
					PORT MAP(in_a => Regs_pipe_out(NRegs-1), in_b => Bi, mult_out => mult);
					
	Pipe_reg_last_gen: Reg_n GENERIC MAP(Nb => 2*Nb)
				PORT MAP(DIN => mult, CLK => CLK, RST_n => RST_n, EN => EN, DOUT => Last_reg_out);
	
	Last_reg_ext(Nb DOWNTO 0) <= Last_reg_out(Nb+Ord DOWNTO Ord);
	Last_reg_ext(2*Nb-1 DOWNTO Nb+1) <= (OTHERS => (Last_reg_ext(Nb)));
	
	Sum: adder_n GENERIC MAP(Nb => Nb+Ord+1)
				 PORT MAP(in_a => SUM_IN, in_b => Last_reg_ext, sum_out => ADD_OUT);
				
END beh;	