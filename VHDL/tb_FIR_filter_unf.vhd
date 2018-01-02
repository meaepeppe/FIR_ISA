LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.math_real.all;
USE STD.textio.all;
USE work.FIR_constants.all;

ENTITY tb_FIR_filter_unf IS
GENERIC(
	N_sample: integer := 202
);
END ENTITY;

ARCHITECTURE test OF tb_FIR_filter_unf IS

	TYPE sample_sign_array IS ARRAY (UO-1 DOWNTO 0) OF SIGNED(Nb-1 DOWNTO 0);
	TYPE vector_test IS ARRAY (N_sample-1 DOWNTO 0) OF INTEGER;
	TYPE coeffs_array IS ARRAY (Ord DOWNTO 0) OF INTEGER;
	TYPE sig_array IS ARRAY (Ord DOWNTO 0) OF SIGNED(Nb-1 DOWNTO 0);

	FILE inputs: text;
	FILE coeff_file: text;
	FILE results: text;
	FILE c_outs_file: text;
	FILE output_diffs: text;
	
	SHARED VARIABLE input_samples, c_outputs: vector_test;

	SIGNAL CLK, RST_n: STD_LOGIC;
	SIGNAL VIN, VOUT: STD_LOGIC;
	SIGNAL sample: sample_sign_array;
	SIGNAL coeffs_std: std_logic_vector ((Ord+1)*Nb - 1 DOWNTO 0);
	SIGNAL visual_coeffs_integer: coeffs_array;
	
	SIGNAL VIN_array: STD_LOGIC_VECTOR(2 DOWNTO 0);
		
	SIGNAL regToDIN, DOUTtoReg, DINconverted, filter_out: IO_array;
	
	COMPONENT FIR_Filter_Unf IS
	PORT(
		CLK, RST_n:	IN STD_LOGIC;
		VIN:	IN STD_LOGIC;
		DIN: 	IN IO_array;
		Coeffs:	IN	STD_LOGIC_VECTOR(((Ord+1)*Nb)-1 DOWNTO 0); --# of coeffs IS N+1
		VOUT:	OUT STD_LOGIC;
		DOUT:	OUT IO_array 
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

Conv_DIN: FOR i IN 0 TO UO-1 GENERATE
	DINconverted(i) <= std_logic_vector(sample(i));
END GENERATE;

VIN_array(0) <= VIN;

VIN_REGS:	FOR i IN 0 TO 1 GENERATE
	REGS_VIN: Reg_n
		GENERIC MAP (Nb => 1)
		PORT MAP(CLK => CLK, RST_n => RST_n, EN => '1', DIN => VIN_array(i DOWNTO i), DOUT => VIN_array(i+1 DOWNTO i+1));
	END GENERATE;

DUT: FIR_filter_Unf
	PORT MAP (CLK => CLK, RST_n => RST_n, VIN => VIN_array(2), DIN => regToDIN,  
						Coeffs => coeffs_std, VOUT => VOUT, DOUT => DOUTtoReg);
	
in_reg_layer: FOR i IN 0 TO UO-1 GENERATE
				REG_IN: Reg_n 
					GENERIC MAP (Nb => DINconverted(i)'LENGTH)
					PORT MAP (CLK => CLK, RST_n => RST_n, EN => VIN_array(1), DIN => DINconverted(i), DOUT => regToDIN(i) );
				END GENERATE;
				
out_reg_layer: FOR i IN 0 TO UO-1 GENERATE
				REG_OUT: Reg_n
					GENERIC MAP (Nb => DOUTtoReg(i)'LENGTH)
					PORT MAP (CLK => CLK, RST_n => RST_n, EN => VOUT, DIN => DOUTtoReg(i), DOUT => filter_out(i) );
				END GENERATE;
	
CLK_gen: PROCESS
	BEGIN
		CLK <= '0';
		WAIT FOR 10 ns;
		CLK <= '1';
		WAIT FOR 10 ns;
	END PROCESS;

VIN_RST_n_gen: PROCESS
BEGIN
	VIN <= '0';
	RST_n <= '0';
	
	WAIT FOR 10 ns;
	RST_n <= '1';
	
	WAIT FOR 5 ns;
	VIN <= '1';
	
	WAIT FOR 745 ns;
	VIN <= '0';
	
	WAIT FOR 60 ns;
	VIN <= '1';
	
	WAIT FOR 600 ns;
	VIN <= '0';
	WAIT;
END PROCESS;
	
test_input_read: PROCESS
	VARIABLE iLine,cLine, coutLine: LINE;
	VARIABLE i,j,k: INTEGER := 0;
	VARIABLE coeffs_integer: coeffs_array;
BEGIN
		file_open(inputs, "samples.txt", READ_MODE);
		WHILE (NOT ENDFILE(inputs)) LOOP
			READLINE(inputs, iLine);
			READ(iLine, input_samples(i));
			i := i+1;
		END LOOP;
		file_close(inputs);
		file_open(coeff_file, "coeffs.txt", READ_MODE);
		WHILE (NOT ENDFILE(coeff_file)) LOOP
			READLINE(coeff_file, cLine);
			READ(cLine, coeffs_integer(j));
			j := j+1;
		END LOOP;
		file_close(coeff_file);
		visual_coeffs_integer <= coeffs_integer;
		
		file_open(c_outs_file, "c_outputvectors.txt", READ_MODE);
		WHILE (NOT ENDFILE(c_outs_file)) LOOP
			READLINE(c_outs_file, coutLine);
			READ(coutLine, c_outputs(k));
			k := k+1;
		END LOOP;
		file_close(c_outs_file);
		
		FOR k IN 0 TO Ord LOOP
			coeffs_std((k+1)*Nb-1 DOWNTO k*Nb)<= std_logic_vector(to_signed(coeffs_integer(k),Nb));
		END LOOP;
		
		WAIT;
END PROCESS;
	
test_results_write: PROCESS(CLK)
	VARIABLE oLine: LINE;
	VARIABLE i,j: INTEGER := 0;
	VARIABLE diff: INTEGER := 0;
	VARIABLE opened_flag : INTEGER := 0;
	BEGIN
		IF CLK'EVENT AND CLK = '1' THEN
			IF opened_flag = 0 THEN
				file_open(results, "output_vectors_unfolded.txt", WRITE_MODE);
				file_open(output_diffs, "output_diffs.txt", WRITE_MODE);
				opened_flag := 1;
			END IF;
			IF VIN = '1' AND i <= (input_samples'LENGTH -1 - UO) THEN
				FOR j IN 0 TO UO-1 LOOP
					sample(j) <= to_signed(input_samples(i+j),sample(j)'LENGTH);
				END LOOP;
				i:= i+UO;
			END IF;
		END IF;
		IF CLK'EVENT AND CLK = '1' THEN
			IF VOUT = '1' THEN
				FOR k IN 0 TO UO-1 LOOP
					WRITE(oLine, to_integer(signed(DOUTtoReg(k))));
					WRITELINE(results, oLine);
				END LOOP;
				
				FOR k IN 0 TO UO-1 LOOP
					diff := (to_integer(signed(DOUTtoReg(k))) - c_outputs(j+k));
					IF(diff /= 0) THEN
						WRITE(oLine, diff);
						WRITE(oLine, string'("   Sample: "));
						WRITE(oLine, (j+k+1));
						WRITELINE(output_diffs, oLine);
					END IF;
				END LOOP;
				j := j+UO;
				
			END IF;
		END IF;
	END PROCESS;
	
END test;