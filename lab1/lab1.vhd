---------------------------------------------------------------------
--
--  Fichero:
--    lab1.vhd  14/7/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Laboratorio 1
--
--  Notas de diseño:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab1 is
  port (
    switches_n : in  std_logic_vector(7 downto 0);
    pbs_n      : in  std_logic_vector(1 downto 0);
    leds       : out std_logic_vector(7 downto 0);
    upSegs     : out std_logic_vector(7 downto 0);
    leftSegs   : out std_logic_vector(7 downto 0);
    rightSegs  : out std_logic_vector(7 downto 0)
  );
end lab1;

---------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of lab1 is

  signal opCode    : std_logic_vector(1 downto 0); 
  signal leftOp    : signed(7 downto 0);
  signal rightOp   : signed(7 downto 0);
  signal result    : signed(7 downto 0);
  signal opCodeAux : std_logic_vector(3 downto 0);
  
begin
  
  opCode  <= not pbs_n;
  leftOp  <= resize(signed(not switches_n(7 downto 4)), 8);
  rightOp <= resize(signed(not switches_n(3 downto 0)), 8);

  ALU:
  with opCode select
   result <= 
		leftOp + rightOp when "00",
		leftOp - rightOp when "01",
		not rightOp  	  when "10",
		leftOp(3 downto 0) * rightOp(3 downto 0) when others;
    
  leftConverter : bin2segs 
  port map ( bin => std_logic_vector(result(7 downto 4)), dp => '0', segs => leftSegs );
  
  rigthConverter : bin2segs
  port map ( bin => std_logic_vector(result(3 downto 0)), dp => '0', segs => rightSegs );

  opCodeAux <= "00" & opCode;
  upConverter : bin2segs
  port map ( bin => opCodeAux, dp => '0', segs => upSegs );

  leds <= not(switches_n);
  
end syn;
