LIBRARY ieee;
USE ieee.numeric_std.all;
USE ieee.math_real.all;

PACKAGE FIR_constants IS
	
	CONSTANT Nb : INTEGER := 9;
	CONSTANT Ord: INTEGER := 8;
	CONSTANT UO: INTEGER := 3;
	CONSTANT Nbmult: INTEGER := 10;
	CONSTANT Nbadder: INTEGER:= Nb; --NUM_BITS_MULT + integer(floor(log2(real(FIR_ORDER+1))));
	
END FIR_constants;

PACKAGE BODY FIR_constants IS
END PACKAGE BODY FIR_constants;