---------------------------------------------------------------------
--
--  Fichero:
--    modcounter.vhd  14/7/2015
--
--    (c) J.M. Mendias
--    Diseo Automtico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Propsito:
--    Contador ascendente genrico (en nm. de bits y valor mximo)
--
--  Notas de diseo:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.common.all;

entity modCounter is
  generic
  (
    MAXVALUE : natural   -- valor maximo alcanzable
  );
  port
  (
    rst_n : in  std_logic;   -- reset asncrono del sistema (a baja)
    clk   : in  std_logic;   -- reloj del sistema
    clear : in  std_logic;   -- puesta a 0 sincrona
    ce    : in  std_logic;   -- capacitacion de cuenta
    tc    : out std_logic;   -- fin de cuenta
    count : out std_logic_vector(log2(MAXVALUE)-1 downto 0)   -- cuenta
  );
end modCounter;

---------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;

architecture syn of modCounter is

  signal cs : unsigned(count'range);

begin

  stateReg:
  process (rst_n, clk)
  begin
    if rst_n='0' then
      cs <= (others => '0');
    elsif rising_edge(clk) then
      if clear='1' then
        cs <= (others => '0');
      elsif ce='1' then
        if cs=MAXVALUE then
          cs <= (others => '0');
        else 
          cs <= cs + 1;
        end if;
      end if;
    end if;
  end process;

  count <= std_logic_vector(cs);
  
  tc <= 
    '1' when ce='1' and cs=MAXVALUE else
    '0'; 

end syn;
