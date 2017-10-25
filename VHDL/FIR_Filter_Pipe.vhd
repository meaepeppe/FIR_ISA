LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY FIR_Filter_Pipe IS
	GENERIC(
			Ord: INTEGER := 8; --Filter Order
			Nb: INTEGER := 9; --# of bits
			PO: INTEGER := 3 -- Pipeline Order
			);
	PORT(
		CLK, RST_n:	IN STD_LOGIC;
		VIN:	IN STD_LOGIC;
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		Coeffs:	IN	STD_LOGIC_VECTOR(((Ord+1)*Nb)-1 DOWNTO 0); --# of coeffs IS N+1
		VOUT: OUT STD_LOGIC;
		DOUT: OUT STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0)
	);
END ENTITY;


ARCHITECTURE beh OF FIR_Filter_Pipe IS

		
	TYPE sum_0_3_array IS ARRAY (0 TO 3) OF STD_LOGIC_VECTOR(Ord+Nb DOWNTO 0);
	TYPE sum_3_6_array IS ARRAY (3 TO 6) OF STD_LOGIC_VECTOR(Ord+Nb DOWNTO 0);
	TYPE sum_6_8_array IS ARRAY(6 TO 8) OF STD_LOGIC_VECTOR(Ord+Nb DOWNTO 0);
	TYPE sig_array IS ARRAY (Ord DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	TYPE Reg_array IS ARRAY (Ord DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	
	SIGNAL Bi: sig_array; -- there IS Ord instead of Ord-1 becaUSE the coeffs are Ord+1
	SIGNAL REG_OUT_array: sig_array;
	SIGNAL Sum_0_3: sum_0_3_array;
	SIGNAL Sum_3_6: sum_3_6_array;
	SIGNAL Sum_6_8: sum_6_8_array;
	
	SIGNAL DIN_mult: STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	--SIGNAL VIN_Delay: STD_LOGIC_VECTOR(Ord DOWNTO 0); -- PROVVISORIA
	SIGNAL tmp: STD_LOGIC_VECTOR(Ord+Nb DOWNTO 0);
	
	COMPONENT Cell_Pipe IS 
		GENERIC(Nb:INTEGER:=9;
				Ord: INTEGER := 8;
				NRegs: INTEGER := 1); -- Num of Pipeline Registers
		PORT(
			CLK, RST_n, EN : IN STD_LOGIC;
			DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
			SUM_IN: IN STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0);
			Bi: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
			REG_OUT : BUFFER STD_LOGIC_VECTOR(Nb-1 DOWNTO 0); 
			ADD_OUT: OUT STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0) -- ADD_OUT has one more bit than the inputs
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

BEGIN
	-- DOUT Generation
	
	Coeff_gen: FOR i IN 0 to Ord GENERATE
		Bi(i) <= Coeffs(((i+1)*Nb)-1 DOWNTO (i*Nb));
	END GENERATE;
	
	DIN_mult_gen: mult_n GENERIC MAP(Nb => Nb)
						 PORT MAP(in_a => DIN, in_b => Bi(0), mult_out => DIN_mult);	
	
	REG_OUT_array(0) <= DIN;
	
	DIN_Mult_Pipe: Reg_n GENERIC MAP( Nb => 2*Nb)
						PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN,
						DIN => DIN_mult,
						DOUT => Sum_0_3(0));
	
	Cells_gen_1: FOR j IN 0 to 2 GENERATE
			Single_cell: Cell_Pipe GENERIC MAP(Nb => Nb, Ord => Ord, NRegs => 1) -- Nb is the # of bits entering the j-th cell
						PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN,
									DIN => REG_OUT_array(j),
									SUM_IN => Sum_0_3(j), 
									Bi => Bi(j+1), 
									REG_OUT => REG_OUT_array(j+1),
									ADD_OUT => Sum_0_3(j+1));
	END GENERATE;
	
	ADD_Pipe_1: Reg_n GENERIC MAP(Nb => Ord+Nb+1)
	PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN,
		DIN => Sum_0_3(3),
		DOUT => Sum_3_6(3));
	
	Cells_gen_2: FOR j IN 3 to 5 GENERATE
			Single_cell: Cell_Pipe GENERIC MAP(Nb => Nb, Ord => Ord, NRegs => 2) -- Nb is the # of bits entering the j-th cell
						PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN,
									DIN => REG_OUT_array(j),
									SUM_IN => Sum_3_6(j), 
									Bi => Bi(j+1), 
									REG_OUT => REG_OUT_array(j+1),
									ADD_OUT => Sum_3_6(j+1));
	END GENERATE;
	
	ADD_Pipe_2: Reg_n GENERIC MAP(Nb => Ord+Nb+1)
	PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN,
		DIN => Sum_3_6(6),
		DOUT => Sum_6_8(6));
	
	Cells_gen_3: FOR j IN 6 to 7 GENERATE
			Single_cell: Cell_Pipe GENERIC MAP(Nb => Nb, Ord => Ord, NRegs => 3) -- Nb is the # of bits entering the j-th cell
						PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN,
									DIN => REG_OUT_array(j),
									SUM_IN => Sum_6_8(j), 
									Bi => Bi(j+1), 
									REG_OUT => REG_OUT_array(j+1),
									ADD_OUT => Sum_6_8(j+1));
	END GENERATE;
	
	DOUT <= Sum_6_8(Ord);
	
	VOUT <= VIN;

END ARCHITECTURE;