library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE STD.textio.all;

ENTITY tb_FIR_filter IS
GENERIC(
	N: integer := 8;
	Nb: integer := 9;
	N_sample: integer := 1000
);
END ENTITY;

ARCHITECTURE test OF tb_FIR_filter IS

	TYPE vector_test IS ARRAY (N_sample-1 DOWNTO 0) OF INTEGER;
	TYPE coeffs_array IS ARRAY (N DOWNTO 0) OF INTEGER;
	TYPE sig_array IS ARRAY (N DOWNTO 0) OF SIGNED(Nb-1 DOWNTO 0);

	FILE inputs: text;
	FILE coeff_file: text;
	SHARED VARIABLE input_samples: vector_test;

	SIGNAL CLK, RST_n: STD_LOGIC;
	SIGNAL VIN, VOUT: STD_LOGIC;
	SIGNAL sample: SIGNED(Nb-1 DOWNTO 0);
	SIGNAL DINconverted: STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	SIGNAL filter_out: STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	SIGNAL coeffs_std: std_logic_vector ((N+1)*Nb - 1 DOWNTO 0);
	SIGNAL visual_coeffs_integer: coeffs_array;
	
	SIGNAL regToDIN: STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	SIGNAL DOUTtoReg: STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
	
	COMPONENT FIR_filter IS
	GENERIC(
		Ord: INTEGER := 8; --Filter Order
		Nb: INTEGER := 9 --# of bits
		);
	PORT(
	CLK, RST_n:	IN STD_LOGIC;
	VIN:	IN STD_LOGIC;
	DIN : IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	Coeffs:	IN	STD_LOGIC_VECTOR(((Ord+1)*Nb)-1 DOWNTO 0); --# of coeffs IS Ord+1
	VOUT: OUT STD_LOGIC;
	DOUT:	OUT STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0)
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
DINconverted <= std_logic_vector(sample);

DUT: FIR_filter 
	PORT MAP (CLK => CLK, RST_n => RST_n, VIN => VIN, DIN => regToDIN,  
						Coeffs => coeffs_std, VOUT => VOUT, DOUT => DOUTtoReg);
	
REG_IN: Reg_n 
	GENERIC MAP (Nb => Nb)
	PORT MAP (CLK => CLK, RST_n => RST_n, EN => VIN, DIN => DINconverted, DOUT => regToDIN );

REG_OUT: Reg_n
	GENERIC MAP (Nb => 2*Nb)
	PORT MAP (CLK => CLK, RST_n => RST_n, EN => VIN, DIN => DOUTtoReg, DOUT => filter_out );
	
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
		file_open(inputs, "input_vectors.txt", READ_MODE);
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
		
		WAIT;
	
	END PROCESS;
	
	test_results_write: PROCESS(CLK)
	VARIABLE oLine: LINE;
	VARIABLE i: INTEGER := 0;
	FILE results: text is out "output_vectors.txt";
	BEGIN
		IF CLK'EVENT AND CLK = '1' THEN
			sample <= to_signed(input_samples(i),sample'LENGTH);
			i:= i+1;
		END IF;
		IF CLK'EVENT AND CLK = '1' AND VIN = '1' THEN
			WRITE(oLine, to_integer(signed(filter_out)));
			WRITELINE(results, oLine);
			
			--IF i = N_sample-1 THEN
			--	VIN <= '0';
			--END IF;
		END IF;
		
	END PROCESS;
	
END test;
