LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
ENTITY mult_n IS
GENERIC(
Nb: INTEGER := 9;
pipe_d: INTEGER:= 5);
PORT(
in_a: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
in_b: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
mult_out: OUT STD_LOGIC_VECTOR(2*Nb-1 DOWNTO 0);
CLK: IN STD_LOGIC;
RST_n: IN STD_LOGIC;
enable_in: IN STD_LOGIC;
enable_out: OUT STD_LOGIC
);
END ENTITY;

ARCHITECTURE beh_mult OF mult_n IS

	TYPE pipe_array_type IS ARRAY(pipe_d DOWNTO 0) OF STD_LOGIC_VECTOR(mult_out'LENGTH-1 DOWNTO 0);

	COMPONENT Reg_n IS
		GENERIC(Nb: INTEGER :=9);
		PORT(
		CLK, RST_n, EN: IN STD_LOGIC;
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
		);
	END COMPONENT;

	SIGNAL mult_signed: SIGNED(mult_out'LENGTH-1 DOWNTO 0);
	SIGNAL pipe_array_signal: pipe_array_type;
	SIGNAL enable_array_signal: STD_LOGIC_VECTOR (pipe_d DOWNTO 0); --ARRAY OF ENABLE SIGNALS
	

BEGIN	

	enable_array_signal(0) <= enable_in;
	
	multiplication: PROCESS(in_a, in_b)
			BEGIN
				mult_signed <= SIGNED(in_a) * SIGNED(in_b);
			END PROCESS;
	
	pipe_array_signal(0) <= STD_LOGIC_VECTOR(mult_signed);
	
	mult_pipe: FOR i IN 0 TO pipe_d-1 GENERATE
		mult_pipe_cell: Reg_n 
				GENERIC MAP (Nb => 2*Nb) 
				PORT MAP (CLK => CLK, RST_n => RST_n, 
						EN => enable_array_signal(i), 
						DIN => pipe_array_signal(i), 
						DOUT => pipe_array_signal(i+1)); 
						
		mult_delay_cell: Reg_n 
				GENERIC MAP (Nb => 1) 
				PORT MAP (CLK => CLK, RST_n => RST_n, EN => '1', 
						DIN => enable_array_signal(i DOWNTO i), 
						DOUT => enable_array_signal(i+1 DOWNTO i+1));
	END GENERATE;
	
	enable_out <= enable_array_signal(pipe_d);
	mult_out <= pipe_array_signal(pipe_d);
	
END beh_mult;
