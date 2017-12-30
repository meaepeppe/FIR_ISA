LIBRARY ieee;
USE ieee.numeric_std.all;
USE ieee.math_real.all;

PACKAGE FIR_constants IS
	
	CONSTANT NUM_BITS : INTEGER := 9;
	CONSTANT FIR_ORDER: INTEGER := 8;
	CONSTANT UNF_ORDER: INTEGER := 3;
	CONSTANT NUM_BITS_MULT: INTEGER := 10;
	CONSTANT Nbadder: INTEGER:= NUM_BITS_MULT + 1 + integer(ceil(log2(real(FIR_ORDER))));
	
END FIR_constants;

PACKAGE BODY FIR_constants IS
END PACKAGE BODY FIR_constants;