LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.FIR_constants.all;

ENTITY FIR_Filter_Unf IS
GENERIC(
		Ord: INTEGER := FIR_ORDER; --Filter Order
		Nb: INTEGER := NUM_BITS; --# of bits
		UO: INTEGER := UNF_ORDER; -- Unfolding Order
		Nbmult: INTEGER := NUM_BITS_MULT
		);
PORT(
	CLK, RST_n:	IN STD_LOGIC;
	VIN:	IN STD_LOGIC;
	DIN: 	IN IO_array;
	Coeffs:	IN	STD_LOGIC_VECTOR(((Ord+1)*Nb)-1 DOWNTO 0); --# of coeffs IS N+1
	VOUT:	OUT STD_LOGIC;
	DOUT:	OUT IO_array 
);
END ENTITY;

ARCHITECTURE beh of FIR_Filter_Unf IS
	
	TYPE REGS_col IS ARRAY(0 TO Ord) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	TYPE REGS_array IS ARRAY(0 TO UO-1) OF REGS_col;
	SIGNAL REGS_sig: REGS_array;
	
	TYPE coeff_array IS ARRAY(Ord DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	SIGNAL Bi: coeff_array;
	
	TYPE sum_out_col IS ARRAY(0 TO Ord) OF STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);
	TYPE sum_out_array IS ARRAY(0 TO UO-1) OF sum_out_col;
	SIGNAL sum_outs: sum_out_array;
	
	TYPE mult_ext_array IS ARRAY(0 TO UO-1) OF STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	SIGNAL mults_ext: mult_ext_array;
	
	
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
	
	COMPONENT Cell_Unf IS
		GENERIC
		(
			Nb: INTEGER := 9;
			Ord: INTEGER := 8;
			Nbmult: INTEGER := 10
		);
		PORT
		(
			DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
			COEFF: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
			SUM_IN: IN STD_LOGIC_VECTOR(NBADDER-1 DOWNTO 0);
			SUM_OUT: OUT STD_LOGIC_VECTOR(NBADDER-1 DOWNTO 0)
		);
	END COMPONENT;

BEGIN

	DIN_link: FOR i IN 0 TO UO-1 GENERATE
	REGs_sig(i)(0) <= DIN(i);
	END GENERATE;

	Coeffs_gen: FOR i IN 0 TO Ord GENERATE
	
		Bi(i) <= Coeffs(((i+1)*Nb)-1 DOWNTO i*Nb);
	
	END GENERATE;
	
	MULTS_gen: FOR i IN 0 TO UO-1 GENERATE
		
		Single_mult: mult_n GENERIC MAP(Nb => Nb)
		PORT MAP(in_a => REGs_sig(i)(0), in_b => Bi(0), mult_out => mults_ext(i));
		
		sum_outs(i)(0)(Nbmult-1 DOWNTO 0) <= mults_ext(i)((mults_ext(i)'LENGTH-1) DOWNTO (mults_ext(i)'LENGTH-1)-(Nbmult-1));
		sum_outs(i)(0)(Nbadder-1 DOWNTO Nbmult) <= (OTHERS => sum_outs(i)(0)(Nbmult-1));
	
	END GENERATE;
	
	REGS_col_gen: FOR Xi IN 0 TO UO-1 GENERATE -- Xi = Row Index of Input signals : 0, 1, ..., UO-1
			REGS_gen: FOR Xj IN 0 TO ((Xi+Ord)/UO)-1 GENERATE  -- Column Index of Input Signals: (Xi+1)/UO, (Xi+1+1)/UO, ..., (Xi+Ord)/UO
			Single_Reg: Reg_n GENERIC MAP(Nb => Nb)
			PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN,
			DIN => REGS_sig(Xi)(Xj),
			DOUT => REGS_sig(Xi)(Xj+1));
		END GENERATE;
	END GENERATE;
	
	Cell_col_gen: FOR Xi IN 0 TO UO-1 GENERATE -- Xi = Row Index of Input signals : 0, 1, ..., UO-1
		Cell_gen: FOR Cj IN 0 TO Ord-1 GENERATE -- Cj = Column Index of Basic Cells: 0, 1, ..., Ord-1
		
			CONSTANT Xj : INTEGER := ((Xi+Cj+1)/UO);  -- Column Index of Input Signals: (Xi+1)/UO, (Xi+1+1)/UO, ..., (Xi+Ord)/UO
			CONSTANT Ci : INTEGER := ((Xi+Cj+1) MOD UO); -- Row Index of Basic Cells: 0, 1, ..., UO-1
			
		BEGIN
		
		Single_Cell: Cell_Unf GENERIC MAP(Nb => Nb, Ord => Ord)
		PORT MAP
		(
			DIN =>  REGS_sig(Xi)(Xj),
			COEFF => Bi(Cj+1),
			SUM_IN => sum_outs(Ci)(Cj),
			SUM_OUT => sum_outs(Ci)(Cj+1)
		);
		END GENERATE;
	END GENERATE;
	
	DOUT_link: FOR i IN 0 TO UO-1 GENERATE
	DOUT(i) <= sum_outs(i)(Ord)(Nb-1 DOWNTO 0);
	END GENERATE;
	
	VOUT <= VIN;
	
END ARCHITECTURE;