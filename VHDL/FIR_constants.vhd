LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.math_real.all;

PACKAGE FIR_constants IS
	
	CONSTANT Nb : INTEGER := 9;
	CONSTANT Ord: INTEGER := 8;
	CONSTANT UO: INTEGER := 1;
	CONSTANT Nbmult: INTEGER := 10;
	CONSTANT Nbadder: INTEGER:= Nb; --NUM_BITS_MULT + integer(floor(log2(real(FIR_ORDER+1))));
	CONSTANT pipe_d: INTEGER := 0;
	CONSTANT IO_buffers: BOOLEAN := TRUE;
	CONSTANT CELLS_PIPE_STAGES: INTEGER := Ord +UO -1;
	TYPE IO_array IS ARRAY(UO-1 DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
	
END FIR_constants;

PACKAGE BODY FIR_constants IS
	
END PACKAGE BODY FIR_constants;