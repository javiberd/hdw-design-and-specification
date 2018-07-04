-------------------------------------------------------------------
--
--  Fichero:
--    edgedetector.vhd  12/7/2013
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Detecta flancos en una entrada binaria lenta
--
--  Notas de diseño:
--    - Asume que el la señal en reposo vale '1'
--
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity edgeDetector is
  port (
    rst_n : in  std_logic;   -- reset asíncrono del sistema (a baja)
    clk   : in  std_logic;   -- reloj del sistema
    x_n   : in  std_logic;   -- entrada binaria con flancos a detectar (a baja en reposo)
    xFall : out std_logic;   -- se activa durante 1 ciclo cada vez que detecta un flanco de subida en x
    xRise : out std_logic    -- se activa durante 1 ciclo cada vez que detecta un flanco de bajada en x
  );
end edgeDetector;

-------------------------------------------------------------------

architecture syn of edgeDetector is 
begin

  process (rst_n, clk)
    variable aux1, aux2: std_logic;
  begin
    xFall <= (not aux1) and aux2;
    xRise <= aux1 and (not aux2);
    if rst_n='0' then
      aux1 := '1';
      aux2 := '1';
    elsif rising_edge(clk) then
      aux2 := aux1;
      aux1 := x_n;           
    end if;
  end process;

end syn;
