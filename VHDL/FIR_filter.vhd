LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.math_real.all;

ENTITY FIR_filter IS
GENERIC(
		Ord: INTEGER := 8; --Filter Order
		Nb: INTEGER := 9; --# of bits
		Nbmult: INTEGER := 10 -- # of significant bits from the multiplier
		);
PORT(
	CLK, RST_n:	IN STD_LOGIC;
	VIN:	IN STD_LOGIC;
	DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	Coeffs:	IN	STD_LOGIC_VECTOR(((Ord+1)*Nb)-1 DOWNTO 0); --# of coeffs IS Ord+1
	VOUT: OUT STD_LOGIC;
	DOUT:	OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
	
);
END ENTITY;

ARCHITECTURE beh_fir OF FIR_filter IS
	
	--CONSTANT Nbadder :INTEGER := Nb + integer(ceil(log2(Ord+1)));
	
	CONSTANT Nbadder: INTEGER := Nbmult+1+integer(ceil(log2(real(Ord))));
	
	TYPE sum_array IS ARRAY (Ord DOWNTO 0) OF STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);
	TYPE sig_array IS ARRAY (Ord DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	
	SIGNAL Bi: sig_array; -- there IS Ord instead of Ord-1 becaUSE the coeffs are Ord+1
	SIGNAL REG_OUT_array: sig_array;
	SIGNAL SUM_OUT_array: sum_array;
	
	SIGNAL DIN_mult: STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	SIGNAL mult_ext: STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);
	
	COMPONENT Cell IS
		GENERIC(Nb:INTEGER:=9;
				Ord: INTEGER := 8; -- Filter Order
				Nbmult: INTEGER := 10
				);
		PORT(
			CLK, RST_n, EN : IN STD_LOGIC;
			DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
			SUM_IN: IN STD_LOGIC_VECTOR((Nbmult+1+integer(ceil(log2(real(Ord)))))-1 DOWNTO 0);
			Bi: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
			REG_OUT : OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0); 
			ADD_OUT: OUT STD_LOGIC_VECTOR((Nbmult+1+integer(ceil(log2(real(Ord)))))-1 DOWNTO 0) -- aggiunti 9 bit di guardia
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
	
	mult_ext(Nbmult-1 DOWNTO 0) <= DIN_mult((DIN_mult'LENGTH)-1 DOWNTO (DIN_mult'LENGTH)-1-(Nbmult-1));
	mult_ext(Nbadder-1 DOWNTO Nbmult) <= (others => mult_ext(Nbmult-1));

	SUM_OUT_array(0) <= mult_ext;
	
	Cells_gen: FOR j IN 0 to Ord-1 GENERATE
			Single_cell: Cell GENERIC MAP(Nb => Nb, Ord => Ord, Nbmult => Nbmult) -- Nb is the # of bits entering the j-th cell
						PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN,
									DIN => REG_OUT_array(j),
									SUM_IN => SUM_OUT_array(j), 
									Bi => Bi(j+1), 
									REG_OUT => REG_OUT_array(j+1),
									ADD_OUT => SUM_OUT_array(j+1));
	END GENERATE;
	
	--DOUT <= SUM_OUT_array(Ord)(Nbadder-1 DOWNTO (Nbadder-1)-(Nb-1));
		DOUT <= SUM_OUT_array(Ord)(Nb-1 DOWNTO 0);
	VOUT <= VIN;
	
END beh_fir;
