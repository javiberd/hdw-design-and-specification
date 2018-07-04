-------------------------------------------------------------------
--
--  Fichero:
--    deskewer.vhd  24/7/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Genera una red de distribución de reloj de bajo skew
--
--  Notas de diseño:
--    - Utiliza 2 DCM uno para la compensación del skew interno
--      de la FPGA y otro para la compensación del skew externo
--      del PCB
--    - Imprescindible para trabajar con la SDRAM a frecuencias
--      superiores a 25 MHz
--    - Vease Xilinx Application Note XAPP462
--
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
 
entity desckewer is
  generic (
    FREQ     : natural           -- frecuencia del reloj de entrada en KHz
  );
  port (
    clkIn    : in  std_logic;    -- oscilador externo
    ready    : out std_logic;    -- se activa cuando las señales de reloj son validas
    intClk   : out std_logic;    -- reloj interno con bajo skew
    extClk   : out std_logic;    -- reloj externo con bajo skew
    extClkFb : in  std_logic     -- señal de feedback del reloj externo (usado para compensar el skew del PCB)
  );
end desckewer;

-------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

architecture syn of desckewer is

  signal clkIn_b, clkfb, clk0 : std_logic;
  signal extClkFb_b : std_logic;
  signal reset : std_logic;
  signal intRdy, extRdy : std_logic;

begin

  -----------------------------------------------------------
  -- Elimina skew del reloj distribuido internamente 
  -----------------------------------------------------------

  clkInBuffer : IBUFG 
    port map ( I => clkIn, O => clkIn_b );
  
  intClkDesckewer : DCM
  generic map 
  (
    CLKDV_DIVIDE          => 2.0, 
    CLKFX_DIVIDE          => 2,
    CLKFX_MULTIPLY        => 2, 
    CLKIN_DIVIDE_BY_2     => FALSE,
    CLKIN_PERIOD          => 1_000_000.0/real(FREQ),   -- periodo de la entrada (en ns)
    CLKOUT_PHASE_SHIFT    => "NONE", 
    CLK_FEEDBACK          => "1X", 
    DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
    DFS_FREQUENCY_MODE    => "LOW",
    DUTY_CYCLE_CORRECTION => FALSE, 
    PHASE_SHIFT           => 0,
    STARTUP_WAIT          => FALSE
  )      
  port map 
  (
    CLK0     => clk0,
    CLK90    => open,
    CLK180   => open,
    CLK270   => open,
    CLK2X    => open,
    CLK2X180 => open,
    CLKDV    => open,
    CLKFX    => open,
    CLKFX180 => open, 
    LOCKED   => intRdy,
    PSDONE   => open,       
    STATUS   => open,
    CLKFB    => clkFb,
    CLKIN    => clkIn_b,
    PSCLK    => '0',
    PSEN     => '0',     
    PSINCDEC => '0', 
    RST      => '0'
  );
  
  clkFbBuffer : BUFG 
  port map ( I => clk0, O => clkFb );
  
  intClk <= clkFb;
  
   -----------------------------------------------------------
  -- Elimina skew del reloj distribuido externamente 
  -----------------------------------------------------------    

  extClkFbBuffer : IBUFG 
  port map ( I => extClkFb, O => extClkFb_b ); 
   
  extclkDesckewer : DCM
  generic map 
  (
    CLKDV_DIVIDE          => 2.0, 
    CLKFX_DIVIDE          => 2,
    CLKFX_MULTIPLY        => 2, 
    CLKIN_DIVIDE_BY_2     => FALSE,
    CLKIN_PERIOD          => 1_000_000.0/real(FREQ),   -- periodo de la entrada (en ns)
    CLKOUT_PHASE_SHIFT    => "NONE", 
    CLK_FEEDBACK          => "1X", 
    DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
    DFS_FREQUENCY_MODE    => "LOW",
    DUTY_CYCLE_CORRECTION => FALSE, 
    PHASE_SHIFT           => 0,
    STARTUP_WAIT          => FALSE
  )      
  port map 
  (
    CLK0     => extClk,
    CLK90    => open,
    CLK180   => open,
    CLK270   => open,
    CLK2X    => open,
    CLK2X180 => open,
    CLKDV    => open,
    CLKFX    => open,
    CLKFX180 => open, 
    LOCKED   => extRdy,
    PSDONE   => open,       
    STATUS   => open,
    CLKFB    => extClkFb_b,
    CLKIN    => clkIn_b,
    PSCLK    => '0',
    PSEN     => '0',     
    PSINCDEC => '0', 
    RST      => reset
  );
    
  resetGenerator : SRL16
  generic map( INIT => X"000F" )
  port map ( CLK => clkIn_b, A0 => '1', A1 => '1', A2 => '1', A3 => '1', D => '0', Q => reset );
 
  ------------------------------------------
    
  ready <= intRdy and extRdy;
  
end syn;
