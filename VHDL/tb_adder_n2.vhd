library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;

ENTITY tb_adder_n2 IS
GENERIC(
	N: INTEGER :=9
);
END tb_adder_n2;

architecture test of tb_adder_n2 is

signal ck, resetn, error: std_logic;
signal in_a, in_b: signed(N-1 downto 0);
signal sum_out: signed(N-1 downto 0);
signal sum_out_std: std_logic_vector(N-1 downto 0);

signal somma: signed(N downto 0);  --------------------

file inputs: text;
file outputs: text;

type test_vector is array (9 downto 0) of INTEGER;

component adder_n is
	generic(
		N: INTEGER := 9
	);
	port(
		in_a: in std_logic_vector(N-1 downto 0);
		in_b: in std_logic_vector(N-1 downto 0);
		sum_out: out std_logic_vector(N-1 downto 0)
	);
end component;

begin
	
DUT: adder_n generic map(N)
			 port map(std_logic_vector(in_a), std_logic_vector(in_b), sum_out_std);
			 
	sum_out <= signed(sum_out_std);	
	somma <= (in_a(N-1) & in_a) + (in_b(N-1) & in_b);

	-- reset_process: process
	-- begin
		-- resetn <= '0';
		-- wait for 25 ns;
		-- resetn <= '1';
		-- wait;
	-- end process;
	
	clock_process: process
	begin
		ck <= '0';
		wait for 10 ns;
		ck <= '1';
		wait for 10 ns;
	end process;
	
	read_process: process
	
	VARIABLE input_vector: test_vector;
	VARIABLE output_vector: test_vector;
	VARIABLE iLine, oLine: LINE;
	VARIABLE i: INTEGER := 0;
	
	begin		
		
		file_open(inputs, "C:\Users\anton\Desktop\ISA\Labs1718\ISA_Lab1\VHDL\QUARTUS\in.txt", READ_MODE);
		file_open(outputs, "C:\Users\anton\Desktop\ISA\Labs1718\ISA_Lab1\VHDL\QUARTUS\out.txt", WRITE_MODE);
		
		in_b <= (others => '0');
		in_b(0) <= '1';
		
		WHILE (NOT ENDFILE(inputs)) LOOP
			READLINE(inputs, iLine);
			READ(iLine, input_vector(i));
			i := i+1;
		END LOOP;
		
		for j in 0 to i-1 loop
			in_a <= to_signed(input_vector(j), in_a'length);
			--sum_out <= to_signed(output_vector(j), sum_out'length);
			wait for 40 ns;
			WRITE(oLine, to_integer(sum_out));
			WRITELINE(outputs, oLine);
		end loop;
		
		file_close(inputs);
		file_close(outputs);
		wait;
		
	end process;
	
end test;