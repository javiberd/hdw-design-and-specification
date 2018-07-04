---------------------------------------------------------------------
--
--  Fichero:
--    lab6.vhd  15/7/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Laboratorio 6
--
--  Notas de diseño:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity damero is
  port ( 
    rst_n : in  std_logic;
    clk   : in  std_logic;
    hSync : out std_logic;
    vSync : out std_logic;
    RGB   : out std_logic_vector(8 downto 0)
  );
end damero;

---------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of damero is

  signal color : std_logic_vector(2 downto 0);
 
  signal line, pixel : std_logic_vector(9 downto 0);
  
  
begin
   

------------------  

  screenInteface: vgaInterface
  generic map ( FREQ => 50_000, SYNCDELAY => 0 )
  port map ( rst_n => rst_n, clk => clk, line => line, pixel => pixel, R => color, G => color, B => color, hSync => hSync, vSync => vSync, RGB => RGB );
 
  color <= (others => pixel(4) xor line(4));

end syn;

