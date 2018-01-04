LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.math_real.all;
USE work.FIR_constants.all;
USE STD.textio.all;

ENTITY tb_FIR_filter_direct IS
GENERIC(
	N_sample: integer := 202
);
END ENTITY;

ARCHITECTURE test OF tb_FIR_filter_direct IS
	
	TYPE vector_test IS ARRAY (N_sample-1 DOWNTO 0) OF INTEGER;
	TYPE coeffs_array IS ARRAY (Ord DOWNTO 0) OF INTEGER;
	TYPE sig_array IS ARRAY (Ord DOWNTO 0) OF SIGNED(Nb-1 DOWNTO 0);

	FILE inputs: text;
	FILE coeff_file: text;
	FILE c_outs_file: text;
	
	SHARED VARIABLE input_samples, c_outputs: vector_test;
	
	SIGNAL tot_pipe_stages: INTEGER;
	SIGNAL CLK, RST_n: STD_LOGIC;
	SIGNAL VIN, VOUT: STD_LOGIC;
	SIGNAL VIN_array: STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL sample: SIGNED(Nb-1 DOWNTO 0);
	SIGNAL DINconverted: STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	SIGNAL filter_out: STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	SIGNAL coeffs_std: std_logic_vector ((Ord+1)*Nb - 1 DOWNTO 0);
	SIGNAL visual_coeffs_integer: coeffs_array;
	
	SIGNAL regToDIN: STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	SIGNAL DOUTtoReg: STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	
	COMPONENT FIR_filter IS
	PORT(
		CLK, RST_n:	IN STD_LOGIC;
		VIN:	IN STD_LOGIC;
		DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		Coeffs:	IN	STD_LOGIC_VECTOR(((Ord+1)*Nb)-1 DOWNTO 0); --# of coeffs IS Ord+1
		VOUT: OUT STD_LOGIC;
		DOUT:	OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
		
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

Tot_latency: PROCESS
BEGIN
	IF IO_buffers = TRUE THEN
		tot_pipe_stages <= 2;
	ELSE
		tot_pipe_stages <= 0;
	END IF;
	
	WAIT;
END PROCESS;


DINconverted <= std_logic_vector(sample);

DUT: FIR_filter 
	PORT MAP (CLK => CLK, RST_n => RST_n, VIN => VIN_array(2), DIN => regToDIN,  
						Coeffs => coeffs_std, VOUT => VOUT, DOUT => DOUTtoReg);
	
VIN_array(0) <= VIN;
VIN_REGS:	FOR i IN 0 TO 1 GENERATE
	REGS_VIN: Reg_n
		GENERIC MAP (Nb => 1)
		PORT MAP(CLK => CLK, RST_n => RST_n, EN => '1', DIN => VIN_array(i DOWNTO i), DOUT => VIN_array(i+1 DOWNTO i+1));
	END GENERATE;	
REG_IN: Reg_n 
	GENERIC MAP (Nb => Nb)
	PORT MAP (CLK => CLK, RST_n => RST_n, EN => VIN_array(1), DIN => DINconverted, DOUT => regToDIN );

REG_OUT: Reg_n
	GENERIC MAP (Nb => Nb)
	PORT MAP (CLK => CLK, RST_n => RST_n, EN => VOUT, DIN => DOUTtoReg, DOUT => filter_out );
	
CLK_gen: PROCESS
	BEGIN
		CLK <= '0';
		WAIT FOR 10 ns;
		CLK <= '1';
		WAIT FOR 10 ns;
	END PROCESS;

VIN_RST_gen: PROCESS

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
	
	WAIT FOR 3280 ns;
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
		
		FOR i IN 0 TO Ord LOOP
			coeffs_std((i+1)*Nb-1 DOWNTO i*Nb)<= std_logic_vector(to_signed(coeffs_integer(i),Nb));
		END LOOP;
		
		WAIT;
END PROCESS;
	
test_results_write: PROCESS(CLK)
	VARIABLE oLine: LINE;
	VARIABLE i, j: INTEGER := 0;
	VARIABLE diff: INTEGER := 0;
	FILE results: text is out "output_vectors_direct.txt";
	FILE output_diffs: text is out "output_diffs.txt";
	BEGIN
		IF CLK'EVENT AND CLK = '1' THEN
			IF VIN = '1' THEN
				sample <= to_signed(input_samples(i),sample'LENGTH);
				i:= i+1;
			END IF;
		END IF;
		IF CLK'EVENT AND CLK = '1' THEN
			IF VOUT = '1' THEN
				WRITE(oLine, to_integer(signed(DOUTtoReg)));
				WRITELINE(results, oLine);
				
				diff := (to_integer(signed(DOUTtoReg)) - c_outputs(j));
				
				IF(diff /= 0) THEN
					WRITE(oLine, diff);
					WRITE(oLine, string'("   Sample: "));
					WRITE(oLine, (j+1));
					WRITELINE(output_diffs, oLine);
				END IF;
				j := j+1;
			END IF;
		END IF;
		
	END PROCESS;
	
END test;
