library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

ENTITY tb_adder_n IS
GENERIC(
	N: INTEGER :=9
);
END tb_adder_n;

architecture test of tb_adder_n is

signal ck, resetn, error: std_logic;
signal in_a, in_b: signed(N-1 downto 0);
signal sum_out: signed(N downto 0);
signal sum_out_std: std_logic_vector(N downto 0);

component adder_n is
	generic(
		N: INTEGER := 9
	);
	port(
		in_a: in std_logic_vector(N-1 downto 0);
		in_b: in std_logic_vector(N-1 downto 0);
		sum_out: out std_logic_vector(N downto 0)
	);
end component;

begin
	
DUT: adder_n generic map(N)
			 port map(std_logic_vector(in_a), std_logic_vector(in_b), sum_out_std);
			 
	sum_out <= signed(sum_out_std);	

	reset_process: process
	begin
		resetn <= '0';
		wait for 25 ns;
		resetn <= '1';
		wait;
	end process;
	
	clock_process: process
	begin
		ck <= '0';
		wait for 10 ns;
		ck <= '1';
		wait for 10 ns;
	end process;
	
	test_process: process(ck)
	begin
		if ck'event and ck = '1' then
			if resetn = '0' then
				in_a <= to_signed(-2**(N-1), in_a'length);            --siccome abbiamo scelto signed partiamo dal valore minimo in complemento a due
				in_b <= to_signed(-2**(N-1), in_b'length);
			else			
				in_a <= in_a + 1;
			
				if in_a = to_signed(2**(N-1) - 1, in_a'length) then       --quando a arriva a fondo scala incrementa b
					in_a <= to_signed(-2**(N-1), in_a'length);
					in_b <= in_b + 1;
				end if;
				
				if in_b = to_signed(2**(N-1) - 1, in_b'length) then       --quando b arriva a fondo scala resetta entrambi i contatori
					in_a <= to_signed(-2**(N-1), in_a'length);
					in_b <= to_signed(-2**(N-1), in_b'length);
				end if;
			end if;
		end if;
	end process;
	
	compare_process: process(in_a, in_b, sum_out)
	begin
		if ((in_a(N-1) & in_a) + (in_b(N-1) & in_b)) = sum_out then
			error <= '0';
		else
			error <= '1';
		end if;
	end process;
	
end test;