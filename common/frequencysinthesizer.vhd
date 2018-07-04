-------------------------------------------------------------------
--
--  Fichero:
--    frequencysinthesizer.vhd  16/10/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Genera una señal de reloj de cierta frecuencia
--
--  Notas de diseño:
--    - Utiliza un DCM
--
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity frequencySynthesizer is
  generic (
    FREQ     : natural;                 -- frecuencia del reloj de entrada en KHz
    MODE     : string;                  -- modo del sintetizador de frecuencia "LOW" o "HIGH"
    MULTIPLY : natural range 2 to 32;   -- factor por el que multiplicar la frecuencia de entrada 
    DIVIDE   : natural range 1 to 32    -- divisor por el que dividir la frecuencia de entrada
  );
  port (
    clkIn  : in  std_logic;   -- reloj de entrada
    ready  : out std_logic;   -- indica si el reloj de salida es válido
    clkOut : out std_logic    -- reloj de salida
  );
end frequencySynthesizer;

-------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

architecture syn of frequencySynthesizer is 
begin

   clockManager : DCM
     generic map 
     (
        CLKDV_DIVIDE          => 2.0, 
        CLKFX_DIVIDE          => DIVIDE,
        CLKFX_MULTIPLY        => MULTIPLY, 
        CLKIN_DIVIDE_BY_2     => FALSE,
        CLKIN_PERIOD          => 1_000_000.0/real(FREQ),   -- periodo de la entrada (en ns)
        CLKOUT_PHASE_SHIFT    => "NONE", 
        CLK_FEEDBACK          => "NONE", 
        DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
        DFS_FREQUENCY_MODE    => MODE,
        DUTY_CYCLE_CORRECTION => FALSE, 
        PHASE_SHIFT           => 0,
        STARTUP_WAIT          => FALSE
      )      
      port map 
      (
        CLK0     => open,
        CLK90    => open,
        CLK180   => open,
        CLK270   => open,
        CLK2X    => open,
        CLK2X180 => open,
        CLKDV    => open,
        CLKFX    => clkOut,
        CLKFX180 => open, 
        LOCKED   => ready,
        PSDONE   => open,       
        STATUS   => open,
        CLKFB    => '0',
        CLKIN    => clkIn,
        PSCLK    => '0',
        PSEN     => '0',     
        PSINCDEC => '0', 
        RST      => '0'
      );
      
end syn;