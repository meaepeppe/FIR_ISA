library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE STD.textio.all;

ENTITY tb_FIR_filter_unf IS
GENERIC(
	N: integer := 8;
	Nb: integer := 9;
	N_sample: integer := 201
);
END ENTITY;

ARCHITECTURE test OF tb_FIR_filter_unf IS

	TYPE sample_sign_array IS ARRAY (2 DOWNTO 0) OF SIGNED(Nb-1 DOWNTO 0);
	TYPE vector_test IS ARRAY (N_sample-1 DOWNTO 0) OF INTEGER;
	TYPE coeffs_array IS ARRAY (N DOWNTO 0) OF INTEGER;
	TYPE sig_array IS ARRAY (N DOWNTO 0) OF SIGNED(Nb-1 DOWNTO 0);
	TYPE sample_std_array IS ARRAY (2 DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	TYPE sampleout_std_array IS ARRAY (2 DOWNTO 0) OF STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);

	FILE inputs: text;
	FILE coeff_file: text;
	FILE results: text;
	SHARED VARIABLE input_samples: vector_test;

	SIGNAL CLK, RST_n: STD_LOGIC;
	SIGNAL VIN, VOUT: STD_LOGIC;
	SIGNAL sample: sample_sign_array;
	SIGNAL DINconverted: sample_std_array;
	SIGNAL filter_out: sampleout_std_array;
	SIGNAL coeffs_std: std_logic_vector ((N+1)*Nb - 1 DOWNTO 0);
	SIGNAL visual_coeffs_integer: coeffs_array;
	
	SIGNAL VIN_array: STD_LOGIC_VECTOR(2 DOWNTO 0);
		
	SIGNAL regToDIN: sample_std_array;
	SIGNAL DOUTtoReg: sampleout_std_array;
	
	COMPONENT FIR_filter_Unf IS
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

DINconverted(0) <= std_logic_vector(sample(0));
DINconverted(1) <= std_logic_vector(sample(1));
DINconverted(2) <= std_logic_vector(sample(2));

VIN_array(0) <= VIN;

VIN_REGS:	FOR i IN 0 TO 1 GENERATE
	REGS_VIN: Reg_n
		GENERIC MAP (Nb => 1)
		PORT MAP(CLK => CLK, RST_n => RST_n, EN => '1', DIN => VIN_array(i DOWNTO i), DOUT => VIN_array(i+1 DOWNTO i+1));
	END GENERATE;

DUT: FIR_filter_Unf
	PORT MAP (CLK => CLK, RST_n => RST_n, VIN => VIN_array(2), DIN_0 => regToDIN(0),  
						DIN_1 => regToDIN(1), DIN_2 => regToDIN(2), 
						Coeffs => coeffs_std, VOUT => VOUT, DOUT_0 => DOUTtoReg(0),
						DOUT_1 => DOUTtoReg(1), DOUT_2 => DOUTtoReg(2));
	
in_reg_layer: FOR i IN 0 TO 2 GENERATE
				REG_IN: Reg_n 
					GENERIC MAP (Nb => Nb)
					PORT MAP (CLK => CLK, RST_n => RST_n, EN => VIN_array(1), DIN => DINconverted(i), DOUT => regToDIN(i) );
				END GENERATE;
out_reg_layer: FOR i IN 0 TO 2 GENERATE
				REG_OUT: Reg_n
					GENERIC MAP (Nb => 2*Nb)
					PORT MAP (CLK => CLK, RST_n => RST_n, EN => VOUT, DIN => DOUTtoReg(i), DOUT => filter_out(i) );
				END GENERATE;
	
CLK_gen: PROCESS
	BEGIN
		CLK <= '0';
		WAIT FOR 10 ns;
		CLK <= '1';
		WAIT FOR 10 ns;
	END PROCESS;
		
test_input_read: PROCESS
	VARIABLE iLine,cLine: LINE;
	VARIABLE i,j: INTEGER := 0;
	VARIABLE coeffs_integer: coeffs_array;
	BEGIN
	VIN <= '0';
	RST_n <= '0';
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
		FOR i IN 0 TO N LOOP
			coeffs_std((i+1)*Nb-1 DOWNTO i*Nb)<= std_logic_vector(to_signed(coeffs_integer(i),Nb));
		END LOOP;
		
		WAIT FOR 10 ns;
		RST_n <= '1';
		WAIT FOR 5 ns;
		VIN <= '1';
		
		WAIT FOR 745 ns;
		VIN <= '0';
		WAIT FOR 60 ns;
		VIN <= '1';
		--WAIT FOR 600 ns;
		--VIN <= '0';
		
		--WAIT FOR 1345 ns;
		--VIN <= '0';
		WAIT;
	
	END PROCESS;
	
test_results_write: PROCESS(CLK)
	VARIABLE oLine: LINE;
	VARIABLE i: INTEGER := 0;
	BEGIN
		file_open(results, "output_vectors_unfolded.txt", WRITE_MODE);
		IF CLK'EVENT AND CLK = '1' THEN
			IF VIN = '1' AND i <= input_samples'LENGTH - 3 THEN
				sample(0) <= to_signed(input_samples(i),sample(0)'LENGTH);
				sample(1) <= to_signed(input_samples(i+1),sample(1)'LENGTH);
				sample(2) <= to_signed(input_samples(i+2),sample(2)'LENGTH);
				i:= i+3;
			END IF;
		END IF;
		IF CLK'EVENT AND CLK = '1' AND VOUT = '1' THEN
			WRITE(oLine, to_integer(signed(filter_out(0))));
			WRITELINE(results, oLine);
			WRITE(oLine, to_integer(signed(filter_out(1))));
			WRITELINE(results, oLine);
			WRITE(oLine, to_integer(signed(filter_out(2))));
			WRITELINE(results, oLine);
		END IF;
		
	END PROCESS;
	
END test;