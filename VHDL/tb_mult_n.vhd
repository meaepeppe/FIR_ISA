LIBRARY ieee;
USE ieee.STD_LOGIC_1164.all;
USE ieee.numeric_std.all;
USE ieee.math_real.all;

ENTITY tb_mult_n IS
GENERIC(N: INTEGER :=9);
END tb_mult_n;

ARCHITECTURE test OF tb_mult_n IS

SIGNAL ck, resetn, error: STD_LOGIC;
SIGNAL in_a, in_b: SIGNED(N-1 DOWNTO 0);
SIGNAL mult_out: SIGNED(N-1 DOWNTO 0);
SIGNAL mult_out_std: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
SIGNAL mult_cmp: SIGNED(2*N-1 DOWNTO 0);
SIGNAL mult_Nbit: SIGNED(N-1 DOWNTO 0);

component mult_n IS
	GENERIC(
		N: INTEGER := 9
	);
	PORT(
		in_a: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		in_b: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		mult_out: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)
	);
END component;

BEGIN
	
DUT: mult_n GENERIC MAP(N => 9)
			 PORT MAP(in_a => STD_LOGIC_VECTOR(in_a), in_b => STD_LOGIC_VECTOR(in_b), mult_out => mult_out_std);
			 
	mult_out <= SIGNED(mult_out_std);

	reset_PROCESS: PROCESS
	BEGIN
		resetn <= '0';
		WAIT FOR 25 ns;
		resetn <= '1';
		WAIT;
	END PROCESS;
	
	clock_PROCESS: PROCESS
	BEGIN
		ck <= '0';
		WAIT FOR 10 ns;
		ck <= '1';
		WAIT FOR 10 ns;
	END PROCESS;
	
	test_PROCESS: PROCESS(ck)
	BEGIN
		IF ck'event and ck = '1' THEN
			IF resetn = '0' THEN
				in_a <= to_SIGNED(-2**(N-1), in_a'length);            --siccome abbiamo scelto SIGNED partiamo dal valore minimo IN complemento a due
				in_b <= to_SIGNED(-2**(N-1), in_b'length);
			ELSE			
				in_a <= in_a + 1;
			
				IF in_a = to_SIGNED(2**(N-1) - 1, in_a'length) THEN       --quando a arriva a fondo scala incrementa b
					in_a <= to_SIGNED(-2**(N-1), in_a'length);
					in_b <= in_b + 1;
				ELSIF in_b = to_SIGNED(2**(N-1) - 1, in_b'length) THEN    --quando b arriva a fondo scala resetta entrambi i contatori      
					in_a <= to_SIGNED(-2**(N-1), in_a'length);
					in_b <= to_SIGNED(-2**(N-1), in_b'length);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
	mult_cmp <= in_a * in_b;
	mult_Nbit <= mult_cmp((2*N)-1 DOWNTO N);
	
	compare_PROCESS: PROCESS(mult_Nbit, mult_out)
	BEGIN

		IF mult_Nbit = mult_out THEN
			error <= '0';
		ELSE
			error <= '1';
		END IF;
	END PROCESS;
	
END test;