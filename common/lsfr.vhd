---------------------------------------------------------------------
--
--  Fichero:
--    lsfr.vhd  24/7/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Genera numeros aleatorios usando un Linear Feedback 
--    Shift-Register
--
--  Notas de diseño:
--    - La semilla no puede ser la secuencia "111...111"
--    - Vease Xilinx Application Note XAPP052
--
---------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity lsfr is
  generic(
    WIDTH : natural   -- anchura del numero aleatorio
  );
  port(
    rst_n  : in  std_logic;   -- reset asíncrono del sistema (a baja)
    clk    : in  std_logic;   -- reloj del sistema
    ce     : in  std_logic;   -- activa la generacion de numeros aleatorios (1 por ciclo de reloj)
    ld     : in  std_logic;   -- carga la semilla
    seed   : in  std_logic_vector(WIDTH-1 downto 0);   -- semilla
    random : out std_logic_vector(WIDTH-1 downto 0)    -- numero aleatorio
   );
end lsfr;

-------------------------------------------------------------------

architecture syn of lsfr is

  signal shtOut      : std_logic_vector(WIDTH-1 downto 0);
  signal feedbackBit : std_logic;

begin
   
  feedbackBit <=
    shtOut(1)  xnor shtOut(0)                                  when WIDTH = 2  else
    shtOut(2)  xnor shtOut(1)                                  when WIDTH = 3  else
    shtOut(3)  xnor shtOut(2)                                  when WIDTH = 4  else
    shtOut(4)  xnor shtOut(2)                                  when WIDTH = 5  else
    shtOut(5)  xnor shtOut(4)                                  when WIDTH = 6  else
    shtOut(6)  xnor shtOut(5)                                  when WIDTH = 7  else
    shtOut(7)  xnor shtOut(5)  xnor shtOut(4)  xnor shtOut(3)  when WIDTH = 8  else
    shtOut(8)  xnor shtOut(4)                                  when WIDTH = 9  else
    shtOut(9)  xnor shtOut(6)                                  when WIDTH = 10 else
    shtOut(10) xnor shtOut(8)                                  when WIDTH = 11 else
    shtOut(11) xnor shtOut(5)  xnor shtOut(3)  xnor shtOut(1)  when WIDTH = 12 else
    shtOut(12) xnor shtOut(3)  xnor shtOut(2)  xnor shtOut(0)  when WIDTH = 13 else
    shtOut(13) xnor shtOut(4)  xnor shtOut(2)  xnor shtOut(0)  when WIDTH = 14 else
    shtOut(14) xnor shtOut(13)                                 when WIDTH = 15 else
    shtOut(15) xnor shtOut(14) xnor shtOut(12) xnor shtOut(3)  when WIDTH = 16 else
    shtOut(16) xnor shtOut(13)                                 when WIDTH = 17 else
    shtOut(17) xnor shtOut(10)                                 when WIDTH = 18 else
    shtOut(18) xnor shtOut(5)  xnor shtOut(1)  xnor shtOut(0)  when WIDTH = 19 else
    shtOut(19) xnor shtOut(16)                                 when WIDTH = 20 else
    shtOut(20) xnor shtOut(18)                                 when WIDTH = 21 else
    shtOut(21) xnor shtOut(20)                                 when WIDTH = 22 else
    shtOut(22) xnor shtOut(17)                                 when WIDTH = 23 else
    shtOut(23) xnor shtOut(22) xnor shtOut(21) xnor shtOut(16) when WIDTH = 24 else
    shtOut(24) xnor shtOut(21)                                 when WIDTH = 25 else
    shtOut(25) xnor shtOut(5)  xnor shtOut(1)  xnor shtOut(0)  when WIDTH = 26 else
    shtOut(26) xnor shtOut(4)  xnor shtOut(1)  xnor shtOut(0)  when WIDTH = 27 else
    shtOut(27) xnor shtOut(24)                                 when WIDTH = 28 else
    shtOut(28) xnor shtOut(26)                                 when WIDTH = 29 else
    shtOut(29) xnor shtOut(5)  xnor shtOut(3)  xnor shtOut(0)  when WIDTH = 30 else
    shtOut(30) xnor shtOut(27)                                 when WIDTH = 31 else
    shtOut(31) xnor shtOut(21) xnor shtOut(1)  xnor shtOut(0)  when WIDTH = 32 else
    shtOut(WIDTH-1);

  shifter:	
  process (rst_n, clk)
  begin
    if rst_n='0' then
	  shtOut <= (others=>'0');
    elsif rising_edge(clk) then
      if ld='1' then
	     shtOut <= seed;
	  elsif ce='1' then
	     shtOut <= shtOut(shtOut'high-1 downto 0) & feedbackBit;
	  end if;
    end if;
  end process;

  random <= shtOut;

end syn;
