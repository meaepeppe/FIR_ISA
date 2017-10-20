LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY FIR_Filter_Unf IS
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
	DOUT_0: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	DOUT_1: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	DOUT_2: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
);
END ENTITY;

ARCHITECTURE beh of FIR_Filter_Unf IS

	TYPE REGS_col IS ARRAY(0 TO 3) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	TYPE REGS_array IS ARRAY(0 TO UO-1) OF REGS_col;
	SIGNAL REGS_sig: REGS_array;
	
	TYPE coeff_array IS ARRAY(0 TO Ord) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	SIGNAL Bi: coeff_array;
	
	TYPE sum_out_col IS ARRAY(0 TO Ord) OF STD_LOGIC_VECTOR(Ord+Nb-1 DOWNTO 0);
	TYPE sum_out_array IS ARRAY(0 TO UO-1) OF sum_out_col;
	SIGNAL sum_outs: sum_out_array;

	COMPONENT Reg_n IS
	GENERIC(Nb: INTEGER :=9);
	PORT(
		CLK, RST_n, EN: IN STD_LOGIC;
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
	);
	END COMPONENT; 
	
	COMPONENT Cell_Unf IS
	GENERIC
	(
		Nb: INTEGER := 9;
		Ord: INTEGER := 8
	);
	PORT
	(
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		COEFF: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		SUM_IN: IN STD_LOGIC_VECTOR(Ord+Nb-1 DOWNTO 0);
		SUM_OUT: OUT STD_LOGIC_VECTOR(Ord+Nb-1 DOWNTO 0)
	);
	END COMPONENT;

BEGIN

	REGs_sig(0)(0) <= DIN_0;
	REGs_sig(1)(0) <= DIN_1;
	REGs_sig(2)(0) <= DIN_2;

	
	REGS_0_col_gen: FOR j IN 0 TO 1 GENERATE
		Single_Reg: Reg_n GENERIC MAP(Nb => Nb)
			PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN,
			DIN => REGS_sig(0)(j),
			DOUT => REGS_sig(0)(j+1));
	END GENERATE;
	
	REGS_1_2_row_gen: FOR i IN 1 TO UO-1 GENERATE --Generazione Registri
		REGS_1_2_col_gen: FOR j IN 0 TO 2 GENERATE
			Single_Reg: Reg_n GENERIC MAP(Nb => Nb)
			PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN,
			DIN => REGS_sig(i)(j),
			DOUT => REGS_sig(i)(j+1));
		END GENERATE;
	END GENERATE;
		
	Mult_col_gen: FOR i IN 0 TO UO-1 GENERATE
		Mult_gen: FOR j IN 0 TO Ord-1 GENERATE 
		Single_Cell: Cell_Unf GENERIC MAP(Nb => Nb, Ord => Ord)
		PORT MAP
		(
			DIN =>  REGS_sig(i)((i+j+1)/UO),
			COEFF => Bi(j),
			SUM_IN => sum_outs((i+j+1) MOD UO)(j),
			SUM_OUT => sum_outs((i+j+1) MOD UO)(j+1)
		);
		END GENERATE;
	END GENERATE;
	
	DOUT_0 <= sum_outs(0)(Ord)(Ord+Nb-1 DOWNTO Ord);
	DOUT_1 <= sum_outs(1)(Ord)(Ord+Nb-1 DOWNTO Ord);
	DOUT_2 <= sum_outs(2)(Ord)(Ord+Nb-1 DOWNTO Ord);
END ARCHITECTURE;