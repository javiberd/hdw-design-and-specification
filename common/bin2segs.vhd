---------------------------------------------------------------------
--
--  Fichero:
--    bin2segs.vhd  14/7/2015
--
--    (c) J.M. Mendias
--    Diseo Automtico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Propsito:
--    Convierte codigo binario a codigo 7-segmentos
--
--  Notas de diseo:
--    - Asume lgica directa
--    - Los segmentos se ordenan en segs alfabticamente de izquierda 
--      a derecha: a=segs(6), b=segs(5)... f=segs(0)
--    - El punto se corresponde con segs(7)
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity bin2segs is
  port (
    -- host side
    bin  : in  std_logic_vector(3 downto 0);   -- codigo binario
    dp   : in  std_logic;                      -- punto
    -- leds side
    segs : out std_logic_vector(7 downto 0)    -- codigo 7-segmentos
  );
end bin2segs;

-------------------------------------------------------------------

architecture syn of bin2segs is
begin 

  segs(7) <= dp; 
  with bin select
    segs(6 downto 0) <= 
      "1111110" when X"0",
      "0110000" when X"1",
      "1101101" when X"2",
      "1111001" when X"3",
      "0110011" when X"4",
      "1011011" when X"5",
      "1011111" when X"6",
      "1110000" when X"7",
      "1111111" when X"8",
      "1110011" when X"9",
      "1110111" when X"A",
      "1111111" when X"B",
      "1001110" when X"C",
      "1111110" when X"D",
      "1001111" when X"E",
      "1000111" when others;
      
end syn;