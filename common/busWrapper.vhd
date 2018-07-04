---------------------------------------------------------------------
--
--  Fichero:
--    buswrapper.vhd  30/9/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Conecta y mapea un dispositivo en un bus elemental síncrono 
--    con señalización por señales de strobe de lectura/escritura 
--    de 1 ciclo de duracion
--
--  Notas de diseño:
--    - Asume que todos los dispositivos conectados al bus son
--      esclavos
-- 
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.common.all;

entity busWrapper is
  generic 
  (
    NUMREG    : natural;   -- numero de registros del dispositivo a conectar al bus
    DWIDTH    : natural;   -- anchura del bus de datos
    AWIDTH    : natural;   -- anchura del bus de direcciones
    BASEADDR  : natural    -- direccion inicial de los registros del dispositivo
  );
  port  
  (
    -- bus side
    wrCE    : in    std_logic;   -- habilitación de escritura
    rdCE    : in    std_logic;   -- habilitación de lectura
    aBus    : in    std_logic_vector(AWIDTH-1 downto 0);   -- direccion
    dBus    : inout std_logic_vector(DWIDTH-1 downto 0);   -- datos
    -- device side
    regSel  : out   std_logic_vector(log2(NUMREG)-1 downto 0);   -- selecciona un registro del dispositivo
    wrE     : out   std_logic;   -- se activa durante 1 ciclo para escribir un registro del dispositivo
    dataIn  : out   std_logic_vector(DWIDTH-1 downto 0);   -- dato a escribir 
    rdE     : out   std_logic;   -- se activa durante 1 ciclo para leer un registro del dispositivo
    dataOut : in    std_logic_vector(DWIDTH-1 downto 0)    -- dato a leer
  );
end busWrapper;

---------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;

architecture syn of busWrapper is

  signal ce : std_logic;
  signal deviceAddr : std_logic_vector(DWIDTH-1 downto 0);
  
begin

  deviceAddr <= std_logic_vector(to_unsigned(BASEADDR, AWIDTH));
  
  addressDecoder :
  ce <= '1' when aBus(AWIDTH-1 downto log2(NUMREG)) = deviceAddr(AWIDTH-1 downto log2(NUMREG)) else '0';
  
  wrE <= wrCE and ce;
  
  rdE <= rdCE and ce;
  
  regSel <= aBus(log2(NUMREG)-1 downto 0);
    
  dataIn <= dBus;
    
  busBuffer :
  dBus <= dataOut when rdCE='1' and ce='1' else (others => 'Z');
  
end syn;
