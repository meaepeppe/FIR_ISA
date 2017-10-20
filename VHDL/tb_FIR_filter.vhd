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

	SIGNAL CLK, RST_n: STD_LOGIC;
	SIGNAL VIN, VOUT: STD_LOGIC;
	SIGNAL sample, filter_out: SIGNED(Nb-1 DOWNTO 0);
	SIGNAL coeffs: SIGNED(((N+1)*Nb)-1 DOWNTO 0);
	
	FILE inputs: text;
	
	TYPE vector_test IS ARRAY (N_sample-1 DOWNTO 0) OF INTEGER;
	TYPE sig_array IS ARRAY (N DOWNTO 0) OF SIGNED(Nb-1 DOWNTO 0);
	
	VARIABLE input_samples: vector_test;
	
BEGIN

DUT: ENTITY WORK.FIR_filter GENERIC MAP (N,Nb) 
	PORT MAP (CLK => CLK, RST_n => RST_n, VIN => VIN, std_logic_vector(DIN) => sample, std_logic_vector(coeffs) => coeffs, VOUT => VOUT, DOUT => filter_out);
	
	CLK_gen: PROCESS
	BEGIN
		CLK <= '0';
		WAIT FOR 10 ns;
		CLK <= '1';
		WAIT FOR 10 ns;
	END PROCESS;
		
	test_input_read: PROCESS
	VARIABLE iLine: LINE;
	VARIABLE i: INTEGER := 0;
	RST_n => '0';
	VIN => '0';
	BEGIN
		file_open(inputs, "C:\Users\anton\Desktop\ISA\Labs1718\ISA_Lab1\VHDL\QUARTUS\input_vectors.txt", READ_MODE);
		WHILE (NOT ENDFILE(inputs)) LOOP
			READLINE(inputs, iLine);
			READ(iLine, input_samples(i));
			i := i+1;
		END LOOP;
		
		WAIT FOR 10 ns;
		RST_n <= '1';
		WAIT FOR 5 ns;
		VIN <= '1';
		file_close(inputs);
		WAIT;
	
	END PROCESS;
	
	test_results_write: PROCESS(CLK)
	VARIABLE oLine: LINE;
	VARIABLE i: INTEGER := 0;
	FILE results: text is out "C:\Users\anton\Desktop\ISA\Labs1718\ISA_Lab1\VHDL\QUARTUS\output_vectors.txt"
	BEGIN
		
		IF CLK'EVENT AND CLK = '1' AND VIN = '1' THEN
			sample <= input_samples(i);
			WRITE(oLine, to_integer(sample));
			WRITELINE(results, oLine);
			i = i+1;
			IF i = N_sample-1 THEN
				VIN <= '0';
			END IF;
		END IF;
		
		IF VIN = '0' THEN
			i = 0;
		END IF;
		
	END PROCESS;
	
END test;