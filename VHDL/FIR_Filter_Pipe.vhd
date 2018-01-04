LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.math_real.all;
USE work.FIR_constants.all;

ENTITY FIR_filter_Pipe IS
PORT(
	CLK, RST_n:	IN STD_LOGIC;
	VIN:	IN STD_LOGIC;
	DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	Coeffs:	IN	STD_LOGIC_VECTOR(((Ord+1)*Nb)-1 DOWNTO 0); --# of coeffs IS Ord+1
	VOUT: OUT STD_LOGIC;
	DOUT:	OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
);
END ENTITY;

ARCHITECTURE beh OF FIR_filter_Pipe IS

	TYPE sum_array IS ARRAY (Ord DOWNTO 0) OF STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);
	TYPE coeff_array IS ARRAY (Ord DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	TYPE sig_array IS ARRAY (Ord-1 DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	
	
	SIGNAL Bi: coeff_array; -- there IS Ord instead of Ord-1 becaUSE the coeffs are Ord+1
	SIGNAL REG_IN_array, Pipe_reg_in: sig_array;
	SIGNAL SUM_OUT_array: sum_array;
	
	SIGNAL DIN_mult: STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	SIGNAL mult_ext: STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);
	SIGNAL Coeffs_delayed: STD_LOGIC_VECTOR(((Ord+1)*Nb)-1 DOWNTO 0);

	SIGNAL VIN_delay_line: STD_LOGIC_VECTOR(Ord DOWNTO 0);
	SIGNAL VIN_vector, VOUT_vector: STD_LOGIC_VECTOR(0 DOWNTO 0);
	
	COMPONENT Cell_Pipe IS 
		PORT(
			CLK, RST_n, EN : IN STD_LOGIC;
			DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
			SUM_IN: IN STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);
			Bi: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
			REG_OUT : BUFFER STD_LOGIC_VECTOR(Nb-1 DOWNTO 0); 
			ADD_OUT: OUT STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0) 
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

-----------------------------------------------------------
------------------------ Input Buffers -------------------- 

	In_buffers_1: IF IO_buffers GENERATE
	
		data_in_reg: Reg_n GENERIC MAP (Nb => Nb)
		PORT MAP
		(
			CLK => CLK,
			RST_n => RST_n,
			EN => VIN,
			DIN => DIN,
			DOUT => REG_IN_array(0)
		);
		
		Coeffs_in_reg: Reg_n GENERIC MAP (Nb => ((Ord+1)*Nb))
		PORT MAP
		(
			CLK => CLK,
			RST_n => RST_n,
			EN => VIN,
			DIN => Coeffs,
			DOUT => Coeffs_delayed
		);
		
		VIN_vector(0) <= VIN;
		
		VIN_in_reg: Reg_n GENERIC MAP (Nb => 1)
		PORT MAP
		(
			CLK => CLK,
			RST_n => RST_n,
			EN => '1',
			DIN => VIN_vector(0 DOWNTO 0),
			DOUT => VIN_delay_line(0 DOWNTO 0)
		); 
		
	END GENERATE;
	
	In_buffers_0: IF NOT(IO_buffers) GENERATE
	
		REG_IN_array(0) <= DIN;
		Coeffs_delayed <= Coeffs;
		VIN_delay_line(0) <= VIN;
	END GENERATE;
	
------------------------------------------------------------
------------------------ VIN Delay Line --------------------

	VIN_Delays: FOR i IN 0 TO VIN_delay_line'LENGTH-2 GENERATE
	Single_delay_VIN: Reg_n GENERIC MAP( Nb => 1)
	PORT MAP
	(
		CLK => CLK, 
		RST_n => RST_n, 
		EN => '1',
		DIN => VIN_delay_line(i DOWNTO i),
		DOUT => VIN_delay_line(i+1 DOWNTO i+1)
	);
	END GENERATE;
	
--------------------------------------------------------------
------------------------ First Multiplier --------------------

	Coeff_gen: FOR i IN 0 to Ord GENERATE
		Bi(i) <= Coeffs_delayed(((i+1)*Nb)-1 DOWNTO (i*Nb));
	END GENERATE;
	
	DIN_mult_gen: mult_n GENERIC MAP(Nb => Nb)
						 PORT MAP(in_a => REG_IN_array(0), in_b => Bi(0), mult_out => DIN_mult);	
	
	DIN_mult_extension_0: IF (Nbadder <= Nbmult) GENERATE
		mult_ext <= DIN_mult((DIN_mult'LENGTH - (Nbmult - Nbadder) -1) DOWNTO (DIN_mult'LENGTH -1 -(Nbmult-1)));
	END GENERATE;
	
	DIN_mult_extension_1: IF (Nbadder > Nbmult) GENERATE
		mult_ext(Nbmult-1 DOWNTO 0) <= DIN_mult((DIN_mult'LENGTH-1) DOWNTO (DIN_mult'LENGTH-1)-(Nbmult-1));
		mult_ext(Nbadder-1 DOWNTO Nbmult) <= (OTHERS => mult_ext(Nbmult-1));
	END GENERATE;
	
	SUM_OUT_array(0) <= mult_ext;
	
-------------------------------------------------------------
------------------------ Matrix of Cells --------------------	

	Cells_gen: FOR j IN 0 to Ord-1 GENERATE
			Single_cell: Cell_Pipe PORT MAP
			(
				CLK => CLK, 
				RST_n => RST_n,
				EN => VIN_delay_line(j),
				DIN => REG_IN_array(j),
				SUM_IN => SUM_OUT_array(j), 
				Bi => Bi(j+1), 
				REG_OUT => Pipe_reg_in(j),
				ADD_OUT => SUM_OUT_array(j+1)
			);
	END GENERATE;

------------------------------------------------------------------------
------------------------ Outside Pipeline Registers --------------------
	
	Pipe_reg_gen: FOR j IN 0 TO Ord-2 GENERATE
		
		Single_Pipe_reg: Reg_n GENERIC MAP (Nb => Pipe_reg_in(j)'LENGTH)
							PORT MAP( CLK => CLK, RST_n => RST_n, EN => VIN_delay_line(j),
									DIN => Pipe_reg_in(j),
									DOUT => REG_IN_array(j+1));
		
	END GENERATE;
	
-----------------------------------------------------------
----------------------- Output Buffers --------------------

	Out_buffers_1: IF IO_buffers GENERATE
	
		data_out_reg: Reg_n GENERIC MAP (Nb => Nb)
		PORT MAP
		(
			CLK => CLK,
			RST_n => RST_n,
			EN => VIN_delay_line((VIN_delay_line'LENGTH-1)),
			DIN => SUM_OUT_array(Ord)(Nb-1 DOWNTO 0),
			DOUT => DOUT
		);
		
		VIN_out_reg: Reg_n GENERIC MAP (Nb => 1)
			PORT MAP
			(
				CLK => CLK,
				RST_n => RST_n,
				EN => '1',
				DIN => VIN_delay_line((VIN_delay_line'LENGTH-1) DOWNTO (VIN_delay_line'LENGTH-1)),
				DOUT => VOUT_vector
			);
		
		VOUT <= VOUT_vector(0);
		
	END GENERATE;
	
	Out_buffers_0: IF NOT(IO_buffers) GENERATE
	
		DOUT <= SUM_OUT_array(Ord)(Nb-1 DOWNTO 0);
		VOUT <= VIN_delay_line(VIN_delay_line'LENGTH-1);
	END GENERATE;
	
	
END beh;


