LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY pipeline IS
GENERIC(
Nb: INTEGER := 9;
pipe_d: INTEGER:= 10);
PORT(
DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
CLK: IN STD_LOGIC;
RST_n: IN STD_LOGIC;
enable_in: IN STD_LOGIC;
enable_out: OUT STD_LOGIC
);
END ENTITY;

ARCHITECTURE structural OF pipeline IS

CONSTANT pipe_depth: INTEGER := pipe_d-2;
TYPE pipe_array_type IS ARRAY(pipe_depth+2 DOWNTO 0) OF STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
SIGNAL pipe_array_signal: pipe_array_type;
SIGNAL enable_array_signal: STD_LOGIC_VECTOR (pipe_depth+2 DOWNTO 0); --ARRAY OF ENABLE SIGNALS


COMPONENT Reg_n IS
		GENERIC(Nb: INTEGER :=9);
		PORT(
		CLK, RST_n, EN: IN STD_LOGIC;
		DIN: IN STD_LOGIC_VECTOR(Nb-1 DOWNTO 0);
		DOUT: OUT STD_LOGIC_VECTOR(Nb-1 DOWNTO 0)
		);
END COMPONENT;

BEGIN
mult_pipe: FOR i IN 0 TO pipe_depth+1 GENERATE
	mult_pipe_cell: Reg_n 
			GENERIC MAP (Nb => Nb) 
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

enable_array_signal(0) <= enable_in;
enable_out <= enable_array_signal(pipe_depth+2);
pipe_array_signal(0)<= DIN;
DOUT <= pipe_array_signal(pipe_depth+2);

END structural;
