library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity data_maker is  
  port (
    CLK     : in  std_logic;
    RST_n   : in  std_logic;
    VOUT    : out std_logic;
    DOUT    : out std_logic_vector(8 downto 0);
	coeffs	: out std_logic_vector(80 downto 0);
    END_SIM : out std_logic);
end data_maker;

architecture beh of data_maker is

  constant tco : time := 1 ns;

  signal sEndSim : std_logic;
  signal END_SIM_i : std_logic_vector(0 to 10);
  
  signal H0      : std_logic_vector(8 downto 0);
  signal H1      : std_logic_vector(8 downto 0);
  signal H2      : std_logic_vector(8 downto 0);
  signal H3      : std_logic_vector(8 downto 0);
  signal H4		 : std_logic_vector(8 downto 0);
  signal H5		 : std_logic_vector(8 downto 0);
  signal H6		 : std_logic_vector(8 downto 0);
  signal H7		 : std_logic_vector(8 downto 0);
  signal H8		 : std_logic_vector(8 downto 0);

begin  -- beh

  H0 <= conv_std_logic_vector(-2,9);
  H1 <= conv_std_logic_vector(-4,9);
  H2 <= conv_std_logic_vector(13,9);
  H3 <= conv_std_logic_vector(68,9);
  H4 <= conv_std_logic_vector(103,9);
  H5 <= conv_std_logic_vector(68,9);
  H6 <= conv_std_logic_vector(13,9);
  H7 <= conv_std_logic_vector(-4,9);
  H8 <= conv_std_logic_vector(-2,9);
  
  coeffs <= H8 & H7 & H6 & H5 & H4 & H3 & H2 & H1 & H0;
	
  process (CLK, RST_n)
    file fp_in : text open READ_MODE is "./samples.txt";
    variable line_in : line;
    variable x : integer;
  begin  -- process
    if RST_n = '0' then                 -- asynchronous reset (active low)
      DOUT <= (others => '0') after tco;      
      VOUT <= '0' after tco;
      sEndSim <= '0' after tco;
    elsif CLK'event and CLK = '1' then  -- rising clock edge
      if not endfile(fp_in) then
        readline(fp_in, line_in);
        read(line_in, x);
        DOUT <= conv_std_logic_vector(x, 9) after tco;
        VOUT <= '1' after tco;
        sEndSim <= '0' after tco;
      else
        VOUT <= '0' after tco;        
        sEndSim <= '1' after tco;
      end if;
    end if;
  end process;

  process (CLK, RST_n)
  begin  -- process
    if RST_n = '0' then                 -- asynchronous reset (active low)
      END_SIM_i <= (others => '0') after tco;
    elsif CLK'event and CLK = '1' then  -- rising clock edge
      END_SIM_i(0) <= sEndSim after tco;
      END_SIM_i(1 to 10) <= END_SIM_i(0 to 9) after tco;
    end if;
  end process;

  END_SIM <= END_SIM_i(10);  

end beh;
