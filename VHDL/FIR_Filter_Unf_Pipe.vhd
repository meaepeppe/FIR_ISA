LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY FIR_Filter_Unf_Pipe IS
GENERIC(
		Ord: INTEGER := 8; --Filter Order
		Nb: INTEGER := 9; --# of bits
		UO: INTEGER := 3 -- Unfolding Order
		);
PORT(
	CLK, RST_n:	IN STD_LOGIC;
	VIN:	IN STD_LOGIC;
	DIN_0 : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	DIN_1 : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	DIN_2 : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	Coeffs:	IN	STD_LOGIC_VECTOR(((Ord+1)*Nb)-1 DOWNTO 0); --# of coeffs IS N+1
	VOUT: OUT STD_LOGIC;
	DOUT_0: OUT STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0);
	DOUT_1: OUT STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0);
	DOUT_2: OUT STD_LOGIC_VECTOR(Nb+Ord DOWNTO 0)
);
END ENTITY;

ARCHITECTURE beh of FIR_Filter_Unf_Pipe IS

	--TYPE REGS_col IS ARRAY(0 TO Ord) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	TYPE REGS_col IS ARRAY(0 TO ((UO+Ord-1)/UO)) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	TYPE REGS_array IS ARRAY(0 TO UO-1) OF REGS_col;
	SIGNAL REGS_sig: REGS_array;
	
	TYPE coeff_array IS ARRAY(Ord DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	SIGNAL Bi: coeff_array;
	
	TYPE sum_out_col IS ARRAY(0 TO Ord) OF STD_LOGIC_VECTOR(Ord+Nb DOWNTO 0);
	TYPE sum_out_array IS ARRAY(0 TO UO-1) OF sum_out_col;
	SIGNAL sum_outs: sum_out_array;
	
	TYPE mult_ext_array IS ARRAY(0 TO UO-1) OF STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	SIGNAL mults_out: mult_ext_array;
	
	TYPE Pipe_mult_col IS ARRAY (2 DOWNTO 0) OF STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	TYPE Pipe_mult_row IS ARRAY (UO-1 DOWNTO 0) OF Pipe_mult_col;
	SIGNAL Pipe_mults: Pipe_mult_row;
	SIGNAL Pipe_outs: Pipe_mult_row;
	
	--SIGNAL VIN_delay_line: STD_LOGIC_VECTOR(11 DOWNTO 0); --(10 DOWNTO 0)
	SIGNAL VIN_delay_line: STD_LOGIC_VECTOR(10 DOWNTO 0); -- 10 signals
	
	TYPE REGS_Delay_wires IS ARRAY(9 DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	TYPE REGS_Delay_col IS ARRAY(((UO-1+Ord)/UO) DOWNTO 0) OF REGS_Delay_wires;
	TYPE REGS_Delay_array IS ARRAY(UO-1 DOWNTO 0) OF REGS_Delay_Col;
	SIGNAL REGS_Delay_sigs: REGS_Delay_array;
	
	
	COMPONENT Reg_n IS
	GENERIC(Nb: INTEGER :=9);
	PORT(
		CLK, RST_n, EN: IN STD_LOGIC;
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
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
	
	COMPONENT Cell_Unf_Pipe IS
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
	END COMPONENT;

BEGIN
	REGs_sig(0)(0) <= DIN_0;
	REGs_sig(1)(0) <= DIN_1;
	REGs_sig(2)(0) <= DIN_2;
	
	-- VIN_array(0) <= VIN;
	-- VIN_array(1) <= VIN_delay_line(1);
	-- VIN_array(VIN_array'LENGTH-1 DOWNTO 2) <= (OTHERS => '1');
	
	VIN_delay_line(0) <= VIN;
	
	VIN_Delays: FOR i IN 0 TO VIN_delay_line'LENGTH-2 GENERATE
		Single_delay_VIN: Reg_n GENERIC MAP( Nb => 1)
								PORT MAP(CLK => CLK, RST_n => RST_n, EN => '1',
								DIN => VIN_delay_line(i DOWNTO i),
								DOUT => VIN_delay_line(i+1 DOWNTO i+1));
	
	END GENERATE;
	
	Coeffs_gen: FOR i IN 0 TO Ord GENERATE
	
		Bi(i) <= Coeffs(((i+1)*Nb)-1 DOWNTO i*Nb);
	
	END GENERATE;
	

	
	REGS_row: FOR i IN 0 TO UO-1 GENERATE
		REGS_col: FOR j IN 0 TO (((i+Ord)/UO) -1) GENERATE --CONTROLLARE
			--REGS_gen: FOR j IN 0 TO (((i+Ord)/UO) + Ord-1) GENERATE
			Single_Reg: Reg_n GENERIC MAP(Nb => Nb)
			PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN_delay_line(0),
			--PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN_delay_line(j),
			DIN => REGS_sig(i)(j),
			DOUT => REGS_sig(i)(j+1));
		END GENERATE;
	END GENERATE;
	
	REGS_Delay_Connect_row: FOR i IN 0 TO UO-1 GENERATE
		REGS_Delay_Connect_col: FOR j IN 0 TO ((i+Ord)/UO) GENERATE
				REGS_Delay_sigs(i)(j)(0) <= REGS_sig(i)(j);
		END GENERATE;
	END GENERATE;
	
	MULTS_gen: FOR i IN 0 TO UO-1 GENERATE
		
		Single_mult: mult_n GENERIC MAP(Nb => Nb)
		PORT MAP(in_a => REGs_sig(i)(0), in_b => Bi(0), mult_out => Pipe_mults(i)(0));
		
		Pipe_mult_col_gen: FOR j IN 0 TO i-1 GENERATE
		
			Pipes_mult: Reg_n GENERIC MAP(Nb => Pipe_mults(i)(j)'LENGTH)
							PORT MAP (CLK => CLK, RST_n => RST_n,
							EN => VIN_delay_line(j),
							DIN => Pipe_mults(i)(j),
							DOUT =>Pipe_mults(i)(j+1));
		
		END GENERATE;
		
		sum_outs(i)(0)(Nb DOWNTO 0) <= Pipe_mults(i)(i)(Nb+Ord DOWNTO Ord);
		sum_outs(i)(0)(Nb+Ord DOWNTO Nb+1) <= (OTHERS => sum_outs(i)(0)(Nb));
	
	END GENERATE;
	
	------------------------------------------------------------- START
	
	REGS_Delay_x00: FOR i IN 0 TO 2 GENERATE
	
		REGS_Delay_x00_gen: Reg_n GENERIC MAP(Nb => Nb)
							PORT MAP(CLK => CLK, RST_n => RST_n,
							EN => VIN_delay_line(i),
							DIN => REGS_Delay_sigs(0)(0)(i),
							DOUT => REGS_Delay_sigs(0)(0)(i+1));
		
	END GENERATE;
	
	REGS_Delay_x01: FOR i IN 0 TO 5 GENERATE

		REGS_Delay_x01_gen: Reg_n GENERIC MAP(Nb => Nb)
							PORT MAP(CLK => CLK, RST_n => RST_n,
							--EN => VIN_delay_line(i+1),
							EN => VIN_delay_line(i),
							DIN => REGS_Delay_sigs(0)(1)(i),
							DOUT => REGS_Delay_sigs(0)(1)(i+1));
	
	END GENERATE;
	
	REGS_Delay_x02: FOR i IN 0 TO 8 GENERATE

		REGS_Delay_x02_gen: Reg_n GENERIC MAP(Nb => Nb)
							PORT MAP(CLK => CLK, RST_n => RST_n,
							--EN => VIN_delay_line(i+2),
							EN => VIN_delay_line(i),
							DIN => REGS_Delay_sigs(0)(2)(i),
							DOUT => REGS_Delay_sigs(0)(2)(i+1));
	
	END GENERATE;
	
	--------------------------------------------------------------
	
	REGS_Delay_x10: FOR i IN 0 TO 1 GENERATE

		REGS_Delay_x10_gen: Reg_n GENERIC MAP(Nb => Nb)
							PORT MAP(CLK => CLK, RST_n => RST_n,
							EN => VIN_delay_line(i),
							DIN => REGS_Delay_sigs(1)(0)(i),
							DOUT => REGS_Delay_sigs(1)(0)(i+1));
	
	END GENERATE;
	
	REGS_Delay_x11: FOR i IN 0 TO 4 GENERATE
	
		REGS_Delay_x11_gen: Reg_n GENERIC MAP(Nb => Nb)
							PORT MAP(CLK => CLK, RST_n => RST_n,
							--EN => VIN_delay_line(i+1),
							EN => VIN_delay_line(i),
							DIN => REGS_Delay_sigs(1)(1)(i),
							DOUT => REGS_Delay_sigs(1)(1)(i+1));
		
	END GENERATE;
	
	REGS_Delay_x12: FOR i IN 0 TO 7 GENERATE
	
		REGS_Delay_x12_gen: Reg_n GENERIC MAP(Nb => Nb)
							PORT MAP(CLK => CLK, RST_n => RST_n,
							--EN => VIN_delay_line(i+2),
							EN => VIN_delay_line(i),
							DIN => REGS_Delay_sigs(1)(2)(i),
							DOUT => REGS_Delay_sigs(1)(2)(i+1));
		
	END GENERATE;
	
	REGS_Delay_x13: FOR i IN 0 TO 6 GENERATE
	
		REGS_Delay_x13_gen: Reg_n GENERIC MAP(Nb => Nb)
							PORT MAP(CLK => CLK, RST_n => RST_n,
							--EN => VIN_delay_line(i+3),
							EN => VIN_delay_line(i),
							DIN => REGS_Delay_sigs(1)(3)(i),
							DOUT => REGS_Delay_sigs(1)(3)(i+1));
		
	END GENERATE;
	
	--------------------------------------------------------------
	
	-- x20 IS NOT NEEDED
	
	REGS_Delay_x21: FOR i IN 0 TO 3 GENERATE
	
		REGS_Delay_x21_gen: Reg_n GENERIC MAP(Nb => Nb)
							PORT MAP(CLK => CLK, RST_n => RST_n,
							--EN => VIN_delay_line(i+1),
							EN => VIN_delay_line(i),
							DIN => REGS_Delay_sigs(2)(1)(i),
							DOUT => REGS_Delay_sigs(2)(1)(i+1));
							
	END GENERATE;
	
	REGS_Delay_x22: FOR i IN 0 TO 6 GENERATE
	
		REGS_Delay_x22_gen: Reg_n GENERIC MAP(Nb => Nb)
							PORT MAP(CLK => CLK, RST_n => RST_n,
							--EN => VIN_delay_line(i+2),
							EN => VIN_delay_line(i),
							DIN => REGS_Delay_sigs(2)(2)(i),
							DOUT => REGS_Delay_sigs(2)(2)(i+1));
							
	END GENERATE;
	
	REGS_Delay_x23: FOR i IN 0 TO 7 GENERATE
	
		REGS_Delay_x23_gen: Reg_n GENERIC MAP(Nb => Nb)
							PORT MAP(CLK => CLK, RST_n => RST_n,
							--EN => VIN_delay_line(i+3),
							EN => VIN_delay_line(i),
							DIN => REGS_Delay_sigs(2)(3)(i),
							DOUT => REGS_Delay_sigs(2)(3)(i+1));
							
	END GENERATE;
	
	-------------------------------------------------------------- END
	
	--TYPE REGS_Delay_col IS ARRAY(((UO-1+Ord)/UO)-1 DOWNTO 0) OF STD_LOGIC_VECTOR(Ord DOWNTO 0);
	--TYPE REGS_Delay_array IS ARRAY(UO-1 DOWNTO 0) OF REGS_Delay_Col;
	--SIGNAL REGS_Delay_sigs: REGS_Delay_array;
	
	
	
	
	Cell_row: FOR i IN 0 TO UO-1 GENERATE
		Cell_col: FOR j IN 0 TO Ord-1 GENERATE 
		Single_Cell: Cell_Unf_Pipe GENERIC MAP(Nb => Nb, Ord => Ord)
		PORT MAP
		(	CLK => CLK, RST_n => RST_n, 
			EN_1 => VIN_delay_line(j+((i+j+1) MOD UO)), 
			EN_2 => VIN_delay_line(j+((i+j+1) MOD UO)),
			DIN => REGS_Delay_sigs(i)((i+j+1)/UO)(j + ((i+j+1) MOD UO)),
			COEFF => Bi(j+1),
			SUM_IN => sum_outs((i+j+1) MOD UO)(j),
			SUM_OUT => sum_outs((i+j+1) MOD UO)(j+1)
		);
		END GENERATE;
	END GENERATE;
	
	
	Pipe_out_rows_gen: FOR i IN 0 TO UO-1 GENERATE
	
		Pipe_outs(i)(0) <= sum_outs(i)(Ord);
		
		Pipe_out_cols_gen: FOR j IN 0 TO 1-i GENERATE
			
			Single_Pipe_out: Reg_n GENERIC MAP(Nb => Pipe_outs(i)(j)'LENGTH)
								PORT MAP(CLK => CLK, RST_n => RST_n,
								EN => VIN_delay_line(8+j+i),
								DIN => Pipe_outs(i)(j),
								DOUT => Pipe_outs(i)(j+1));
		END GENERATE;
	
	END GENERATE;
	DOUT_0 <= Pipe_outs(0)(2);
	DOUT_1 <= Pipe_outs(1)(1);
	DOUT_2 <= Pipe_outs(2)(0);
	
	VOUT <= VIN_delay_line(VIN_delay_line'LENGTH-1);
	
END ARCHITECTURE;