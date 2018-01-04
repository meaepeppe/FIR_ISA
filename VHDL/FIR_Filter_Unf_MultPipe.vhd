LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.FIR_constants.all;

ENTITY FIR_Filter_Unf_MultPipe IS
PORT(
	CLK, RST_n:	IN STD_LOGIC;
	VIN:	IN STD_LOGIC;
	DIN: 	IN IO_array;
	Coeffs:	IN	STD_LOGIC_VECTOR(((Ord+1)*Nb)-1 DOWNTO 0); --# of coeffs IS N+1
	VOUT:	OUT STD_LOGIC;
	DOUT:	OUT IO_array 
);
END ENTITY;

ARCHITECTURE beh of FIR_Filter_Unf_MultPipe IS
	
	TYPE REGS_col IS ARRAY(0 TO ((UO-1+Ord)/UO)) OF STD_LOGIC_VECTOR(DIN(0)'LENGTH-1 DOWNTO 0);
	TYPE REGS_array IS ARRAY(0 TO UO-1) OF REGS_col;
	SIGNAL REGS_sig: REGS_array;
	
	TYPE coeff_array IS ARRAY(Ord DOWNTO 0) OF STD_LOGIC_VECTOR(DIN(0)'LENGTH-1 DOWNTO 0);
	SIGNAL Bi: coeff_array;
	
	TYPE sum_out_col IS ARRAY(0 TO Ord) OF STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);
	TYPE sum_out_array IS ARRAY(0 TO UO-1) OF sum_out_col;
	SIGNAL sum_outs: sum_out_array;
	
	TYPE mult_ext_array IS ARRAY(0 TO UO-1) OF STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	SIGNAL mults_out: mult_ext_array;
	
	TYPE Pipe_out_col IS ARRAY (UO DOWNTO 0) OF STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);  -- (UO-1) are the max number of pipe stages after the array  
	TYPE Pipe_out_row IS ARRAY (UO-1 DOWNTO 0) OF Pipe_out_col;						   -- of cells, then + 1 for the very last
	SIGNAL Pipe_outs: Pipe_out_row;													   -- pipe stage, so in total: UO pipe stages.
																					   -- Then, for UO stages, UO+1 signals needed, so in the end:
																					   -- (UO+1-1 DOWNTO 0)
	
	TYPE Pipe_mult_col IS ARRAY (UO-1 DOWNTO 0) OF STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0); 
	TYPE Pipe_mult_row IS ARRAY (UO-1 DOWNTO 0) OF Pipe_mult_col;
	SIGNAL Pipe_mults: Pipe_mult_row;
	
	SIGNAL VIN_delay_line: STD_LOGIC_VECTOR(CELLS_PIPE_STAGES+1 DOWNTO 0);
	--TYPE VIN_Delay_col IS ARRAY(UO-1 DOWNTO 0) OF STD_LOGIC_VECTOR(CELLS_PIPE_STAGES+1 DOWNTO 0); -- For N stages, N+1 signals are required; 
	--SIGNAL VIN_delay_line: VIN_Delay_col; 														 -- N here is CELLS_PIPE_STAGES = Ord + UO -1,
																								 -- plus 1 for the last pipeline at the output,
																								 -- so in total we have:
																								 -- ((CELLS_PIPE_STAGES+1) +1 -1) DOWNTO 0 =
																								 -- = (Ord + UO) DOWNTO 0 
	
	TYPE REGS_Delay_wires IS ARRAY(Ord+UO-2 DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	TYPE REGS_Delay_col IS ARRAY(((Ord+UO-1)/UO) DOWNTO 0) OF REGS_Delay_wires;
	TYPE REGS_Delay_array IS ARRAY(UO-1 DOWNTO 0) OF REGS_Delay_Col;
	SIGNAL REGS_Delay_sigs: REGS_Delay_array;
	
	
	SIGNAL VIN_vector, VOUT_vector: STD_LOGIC_VECTOR(0 DOWNTO 0);
	SIGNAL Coeffs_delayed: STD_LOGIC_VECTOR(((Ord+1)*Nb)-1 DOWNTO 0);
	
	
	COMPONENT Reg_n IS
	GENERIC(Nb: INTEGER :=9);
	PORT(
		CLK, RST_n, EN: IN STD_LOGIC;
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
	);
	END COMPONENT; 
	
	COMPONENT mult_comb_n IS
	GENERIC(
		Nb: INTEGER := 9
	);
	PORT(
		in_a: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		in_b: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		mult_out: OUT STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0)
	);
	END COMPONENT;
	
	COMPONENT Cell_Unf_Pipe IS
	PORT
	(
		CLK, RST_n: IN STD_LOGIC;
		EN_IN : IN STD_LOGIC;
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		COEFF: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		SUM_IN: IN STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0);
		EN_OUT : OUT STD_LOGIC;
		SUM_OUT: OUT STD_LOGIC_VECTOR(Nbadder-1 DOWNTO 0)
	);
	END COMPONENT;
	
	COMPONENT pipeline IS
	GENERIC(
		Nb: INTEGER := 9;
		pipe_d: INTEGER:= 5);
	PORT(
		CLK: IN STD_LOGIC;
		RST_n: IN STD_LOGIC;
		enable_in: IN STD_LOGIC;
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		enable_out: OUT STD_LOGIC;
		DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
		);
	END COMPONENT;
	
BEGIN

-----------------------------------------------------------
------------------------ Input Buffers -------------------- 

	In_buffers_1: IF IO_buffers GENERATE
	
		REGS_sig_link: FOR i IN 0 TO UO-1 GENERATE
		
			data_in_reg: Reg_n GENERIC MAP (Nb => Nb)
			PORT MAP
			(
				CLK => CLK,
				RST_n => RST_n,
				EN => VIN,
				DIN => DIN(i),
				DOUT => REGs_sig(i)(0)
			);
		END GENERATE;
		
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
				DIN => VIN_vector,
				DOUT => VIN_delay_line(0 DOWNTO 0)
			);
		
	END GENERATE;
	
	In_buffers_0: IF NOT(IO_buffers) GENERATE
	
		REGS_sig_link: FOR i IN 0 TO UO-1 GENERATE
		
			REGs_sig(i)(0) <= DIN(i);
			
		END GENERATE;
		
		Coeffs_delayed <= Coeffs;
		VIN_delay_line(0) <= VIN;
		
	END GENERATE;
------------------------------------------------------------------
------------------------ Data Delay Registers -------------------- 
	
	REGS_row: FOR i IN 0 TO UO-1 GENERATE
		REGS_col: FOR j IN 0 TO (((i+Ord)/UO) -1) GENERATE
		
			Single_Reg: Reg_n GENERIC MAP(Nb => Nb)
			PORT MAP(CLK => CLK, RST_n => RST_n, EN => VIN_delay_line(0),
			DIN => REGS_sig(i)(j),
			DOUT => REGS_sig(i)(j+1));
			
		END GENERATE;
	END GENERATE;
	
	REGS_Delay_Connect_row: FOR i IN 0 TO UO-1 GENERATE
		REGS_Delay_Connect_col: FOR j IN 0 TO ((i+Ord)/UO) GENERATE
		
				REGS_Delay_sigs(i)(j)(0) <= REGS_sig(i)(j);
				
		END GENERATE;
	END GENERATE;

---------------------------------------------------------------
------------------------ First Multipliers -------------------- 
	Coeffs_gen: FOR i IN 0 TO Ord GENERATE
	
		Bi(i) <= Coeffs_delayed(((i+1)*Nb)-1 DOWNTO i*Nb);
	
	END GENERATE;

	MULTS_gen: FOR i IN 0 TO UO-1 GENERATE
		
		Single_mult: mult_comb_n GENERIC MAP(Nb => Nb)
		PORT MAP
		(
			in_a => REGs_sig(i)(0), 
			in_b => Bi(0),
			mult_out => Pipe_mults(i)(0)
		);
		---------------------------------------------------------------
		--------------- First Multipliers' Pipelines ------------------
		----------------- And start of VIN_delay_line -----------------
		
		Pipe_mult_col_condition_0: IF ((i >= 1) AND (i < UO-1)) GENERATE		
			Pipe_mult_col_gen: FOR j IN 0 TO i-1 GENERATE
				Pipes_mult: pipeline GENERIC MAP(Nb => Pipe_mults(i)(j)'LENGTH, pipe_d => pipe_d +1)
					PORT MAP (CLK => CLK,
					RST_n => RST_n,
					enable_in => VIN_delay_line(j),
					DIN => Pipe_mults(i)(j),
					--enable_out => VIN_delay_line(j+1),
					DOUT =>Pipe_mults(i)(j+1));
			END GENERATE;
		END GENERATE;
		
		Pipe_mult_col_condition_1: IF (i = UO-1) GENERATE
			Pipe_mult_col_gen: FOR j IN 0 TO i-1 GENERATE
				Pipes_mult: pipeline GENERIC MAP(Nb => Pipe_mults(i)(j)'LENGTH, pipe_d => pipe_d +1)
					PORT MAP (CLK => CLK,
					RST_n => RST_n,
					enable_in => VIN_delay_line(j),
					DIN => Pipe_mults(i)(j),
					enable_out => VIN_delay_line(j+1),
					DOUT =>Pipe_mults(i)(j+1));
			END GENERATE;
		END GENERATE;
		
		Pipe_mults_extension_0: IF (Nbadder <= Nbmult) GENERATE
			sum_outs(i)(0) <= Pipe_mults(i)(i)((Pipe_mults(i)(i)'LENGTH -(Nbmult - Nbadder) -1) DOWNTO (Pipe_mults(i)(i)'LENGTH-1)-(Nbmult-1));
		END GENERATE;
		Pipe_mults_extension_1: IF (Nbadder > Nbmult) GENERATE
			sum_outs(i)(0)(Nbmult-1 DOWNTO 0) <= Pipe_mults(i)(i)((Pipe_mults(i)(i)'LENGTH-1) DOWNTO (Pipe_mults(i)(i)'LENGTH-1)-(Nbmult-1));
			sum_outs(i)(0)(Nbadder-1 DOWNTO Nbmult) <= (OTHERS => sum_outs(i)(0)(Nbmult-1));
		END GENERATE;
		
	END GENERATE;

--------------------------------------------------------------
------------------------ Data Pipelines ----------------------	
	
	REGS_Delay_row_gen: FOR Xi IN 0 TO UO-1 GENERATE -- Xi = Row Index of Input signals : 0, 1, ..., UO-1
		REGS_Delay_col_gen: FOR Xj IN ((Xi+1)/UO) TO ((Xi+Ord)/UO) GENERATE -- Xj = Column Index of Input signals: 0, 1, ..., Ord-1
		
				CONSTANT Cj_max: INTEGER := (((Xj+1)*UO) -2 -Xi); --Cj_max for each Xj ; Cj = Column Index of Cells: 0, 1, ..., Ord-1
				CONSTANT Ci: INTEGER := ((Xi+Cj_max+1) MOD UO); -- Ci related to Cj_max; Ci = Row Index of Cells: 0, 1, ..., UO-1
				CONSTANT Ci_max : INTEGER := (Xi+(Ord-1)+1) MOD UO; -- Ci computed saturating Cj_max to (Ord-1)
			BEGIN
			REGS_Delay_cond_0: IF (Cj_max >= Ord-1) GENERATE
				single_REGS_Delay: FOR k IN 0 TO ((Ord-1) + Ci_max)-1 GENERATE --Cj_max + Ci_max saturating Cj_max to Ord-1

						single_REGS_pipe: pipeline GENERIC MAP(Nb => REGS_Delay_sigs(0)(0)(0)'LENGTH, pipe_d => pipe_d +1)
							PORT MAP(
								CLK => CLK,
								RST_n => RST_n,
								enable_in => VIN_delay_line(k),
								DIN => REGS_Delay_sigs(Xi)(Xj)(k),
								DOUT => REGS_Delay_sigs(Xi)(Xj)(k+1));
				END GENERATE;
			END GENERATE;
			REGS_Delay_cond_1: IF (Cj_max < Ord-1) GENERATE
				single_REGS_Delay: FOR k IN 0 TO (Cj_max + Ci)-1 GENERATE
				
						single_REGS_pipe: pipeline GENERIC MAP(Nb => REGS_Delay_sigs(0)(0)(0)'LENGTH, pipe_d => pipe_d +1)
							PORT MAP(
								CLK => CLK,
								RST_n => RST_n,
								enable_in => VIN_delay_line(k),
								DIN => REGS_Delay_sigs(Xi)(Xj)(k),
								DOUT => REGS_Delay_sigs(Xi)(Xj)(k+1));
				END GENERATE;
			END GENERATE;
		END GENERATE;
	END GENERATE;
	
------------------------------------------------------------------------------
-------------------------------Matrix of Cells -------------------------------
------------------And Generation of internal VIN_delay_line ------------------

	Cell_row: FOR Xi IN 0 TO UO-1 GENERATE -- Xi = Row Index of Input signals : 0, 1, ..., UO-1
		Cell_col: FOR Cj IN 0 TO Ord-1 GENERATE -- Cj = Column Index of Basic Cells: 0, 1, ..., Ord-1
		
			CONSTANT Xj : INTEGER := ((Xi+Cj+1)/UO);  -- Column Index of Input Signals: (Xi+1)/UO, (Xi+1+1)/UO, ..., (Xi+Ord)/UO
			CONSTANT Ci : INTEGER := ((Xi+Cj+1) MOD UO); -- Row Index of Basic Cells: 0, 1, ..., UO-1
			
		BEGIN
			Single_Cell_cond_0: IF (Ci /= UO-1) GENERATE
			
				Single_Cell: Cell_Unf_Pipe PORT MAP
				(	
					CLK => CLK,
					RST_n => RST_n, 
					EN_IN => VIN_delay_line (Cj + Ci), 
					DIN => REGS_Delay_sigs(Xi)(Xj)(Cj + Ci),
					COEFF => Bi(Cj+1),
					--EN_OUT => VIN_delay_line (Cj + Ci + 1), -- max value for VIN_delay_line in output: Ord+UO-1 = CELLS_PIPE_STAGES
					SUM_IN => sum_outs(Ci)(Cj),
					SUM_OUT => sum_outs(Ci)(Cj+1)
				);
				
			END GENERATE;
			
			Single_Cell_cond_1: IF (Ci = UO-1) GENERATE
			
				Single_Cell: Cell_Unf_Pipe PORT MAP
				(	
					CLK => CLK,
					RST_n => RST_n, 
					EN_IN => VIN_delay_line (Cj + Ci), 
					DIN => REGS_Delay_sigs(Xi)(Xj)(Cj + Ci),
					COEFF => Bi(Cj+1),
					EN_OUT => VIN_delay_line (Cj + Ci + 1), -- max value for VIN_delay_line in output: Ord+UO-1 = CELLS_PIPE_STAGES
					SUM_IN => sum_outs(Ci)(Cj),
					SUM_OUT => sum_outs(Ci)(Cj+1)
				);
			
			END GENERATE;
		END GENERATE;
	END GENERATE;
	
------------------------------------------------------------------
------------------------ Last Pipeline Stages -------------------- 

	Pipe_out_rows_gen: FOR i IN 0 TO UO-1 GENERATE
	
		Pipe_outs(i)(0) <= sum_outs(i)(Ord);
		
		Pipe_out_cond:IF (i < UO-1) GENERATE
			Pipe_out_cols_gen: FOR j IN 0 TO ((UO-1)-(i+1)) GENERATE
	
					Single_Pipe_out: pipeline GENERIC MAP(Nb => Pipe_outs(i)(j)'LENGTH, pipe_d => pipe_d +1)
										PORT MAP(
										CLK => CLK,
										RST_n => RST_n,
										enable_in => VIN_delay_line(Ord+j+i), 
										--enable_out => VIN_delay_line(Ord+j+i+1),
										DIN => Pipe_outs(i)(j),
										DOUT => Pipe_outs(i)(j+1));
										
			END GENERATE;
		END GENERATE;
	END GENERATE;
	
	Last_Pipe_out_cond_1: IF (pipe_d > 0) GENERATE
		Last_Pipe_out_1: FOR i IN 0 TO UO-1 GENERATE

			Single_Pipe_out: pipeline GENERIC MAP(Nb => Pipe_outs(0)(0)'LENGTH, pipe_d => pipe_d)
								PORT MAP(
								CLK => CLK,
								RST_n => RST_n,
								enable_in => VIN_delay_line(CELLS_PIPE_STAGES), 
								enable_out => VIN_delay_line(CELLS_PIPE_STAGES + 1),
								DIN => Pipe_outs(i)(UO-1-i),
								DOUT => Pipe_outs(i)(UO-i));
		END GENERATE;
	END GENERATE;
	
	Last_Pipe_out_cond_0: IF (pipe_d = 0) GENERATE
	
		Last_Pipe_out_0: FOR i IN 0 TO UO-1 GENERATE
			Pipe_outs(i)(UO-i) <= Pipe_outs(i)(UO-1-i);
		END GENERATE;
		
		VIN_delay_line(CELLS_PIPE_STAGES + 1) <= VIN_delay_line(CELLS_PIPE_STAGES);
		
	END GENERATE;

---------------------------------------------------------------
------------------------ Output Buffers -----------------------
	Out_buffers_1: IF IO_buffers GENERATE
	
		DOUT_link: FOR i IN 0 TO UO-1 GENERATE
			--DOUT(i) <= Pipe_outs(i)(UO-i)((DOUT(i)'LENGTH-1) DOWNTO 0);
			data_out_reg: Reg_n GENERIC MAP (Nb => Nb)
				PORT MAP
				(
					CLK => CLK,
					RST_n => RST_n,
					EN => VIN_delay_line(CELLS_PIPE_STAGES + 1),
					DIN => Pipe_outs(i)(UO-i)((DOUT(i)'LENGTH-1) DOWNTO 0),
					DOUT => DOUT(i)
				);
		END GENERATE;
		
		VIN_out_reg: Reg_n GENERIC MAP (Nb => 1)
			PORT MAP
			(
				CLK => CLK,
				RST_n => RST_n,
				EN => '1',
				DIN => VIN_delay_line((CELLS_PIPE_STAGES +1) DOWNTO (CELLS_PIPE_STAGES + 1)),
				DOUT => VOUT_vector
			);
		
		VOUT <= VOUT_vector(0);
	
	END GENERATE;
	
	Out_buffers_0: IF NOT(IO_buffers) GENERATE
	
		DOUT_link: FOR i IN 0 TO UO-1 GENERATE
			DOUT(i) <= Pipe_outs(i)(UO-i)((DOUT(i)'LENGTH-1) DOWNTO 0);
		END GENERATE;
		
		VOUT <= VIN_delay_line(CELLS_PIPE_STAGES +1);
		
	END GENERATE;
	
END ARCHITECTURE;