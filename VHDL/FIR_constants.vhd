LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.math_real.all;

PACKAGE FIR_constants IS
	
	CONSTANT NUM_BITS : INTEGER := 9;
	CONSTANT FIR_ORDER: INTEGER := 8;
	CONSTANT UNF_ORDER: INTEGER := 3;
	CONSTANT NUM_BITS_MULT: INTEGER := 10;
	CONSTANT Nbadder: INTEGER:= NUM_BITS_MULT + integer(floor(log2(real(FIR_ORDER+1))));
	TYPE IO_array IS ARRAY(UNF_ORDER-1 DOWNTO 0) OF STD_LOGIC_VECTOR(NUM_BITS-1 DOWNTO 0);
	
END FIR_constants;

PACKAGE BODY FIR_constants IS
END PACKAGE BODY FIR_constants;