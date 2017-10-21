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
		SUM_IN: IN STD_LOGIC_VECTOR(Nb+Ord-1 DOWNTO 0);
		Bi: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		REG_OUT : BUFFER STD_LOGIC_VECTOR(Nb-1 DOWNTO 0); 
		ADD_OUT: OUT STD_LOGIC_VECTOR(Nb+Ord-1 DOWNTO 0) -- ADD_OUT has one more bit than the inputs
	);
END ENTITY;

ARCHITECTURE beh OF Cell_Pipe IS

	TYPE Reg_sig_array IS ARRAY (3 DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	SIGNAL Regs_pipe_out: Reg_sig_array;
	
	SIGNAL mult: STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	SIGNAL mult_ext: STD_LOGIC_VECTOR(Nb+Ord-1 DOWNTO 0);

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
		mult_out: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
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
			   PORT MAP(DIN => DIN, CLK => CLK, RST_n => RST_n, EN => EN, DOUT => REG_OUT);
	
	Product: mult_n GENERIC MAP(Nb => Nb)
					PORT MAP(in_a => REG_OUT, in_b => Bi, mult_out => mult);
	
	Regs_pipe_out(0) <= mult;
	
	Pipe_Reg_gen: FOR i IN 1 TO NRegs GENERATE
	
		Single_Reg_gen: Reg_n GENERIC MAP(Nb => Nb)
		PORT MAP(CLK => CLK, RST_n => RST_n, EN => EN,
		DIN => Regs_pipe_out(i-1),
		DOUT => Regs_pipe_out(i)
		);
	END GENERATE;
	
	mult_ext(Nb-1 DOWNTO 0) <= Regs_pipe_out(NRegs);
	mult_ext(Nb+Ord-1 DOWNTO Nb) <= (OTHERS => Regs_pipe_out(NRegs)(Nb-1));
	
	Sum: adder_n GENERIC MAP(Nb => Nb+Ord)
				 PORT MAP(in_a => SUM_IN, in_b => mult_ext, sum_out => ADD_OUT);
				
END beh;	