---------------------------------------------------------------------
--
--  Fichero:
--    lab3.vhd  15/7/2015
--
--    (c) J.M. Mendias
--    Diseo Automtico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Propsito:
--    Laboratorio 3
--
--  Notas de diseo:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab3 is
port
(
  rstPb_n    : in  std_logic;
  osc        : in  std_logic;
  enter_n    : in  std_logic;
  switches_n : in  std_logic_vector(7 downto 0);
  leds       : out std_logic_vector(7 downto 0);
  upSegs     : out std_logic_vector(7 downto 0)
);
end lab3;

---------------------------------------------------------------------

use work.common.all;

architecture syn of lab3 is

  component synchronizer
  generic (
    STAGES  : in natural;      -- nmero de biestables del sincronizador
    INIT    : in std_logic     -- valor inicial de los biestables 
  );
  port (
    rst_n : in  std_logic;   -- reset asncrono de entrada (a baja)
    clk   : in  std_logic;   -- reloj del sistema
    x     : in  std_logic;   -- entrada binaria a sincronizar
    xSync : out std_logic    -- salida sincronizada que sique a la entrada
  );
  end component;
  
  component debouncer
  generic(
    FREQ   : natural;  -- frecuencia de operacion en KHz
    BOUNCE : natural   -- tiempo de rebote en ms
  );
  port (
    rst_n  : in  std_logic;   -- reset asncrono del sistema (a baja)
    clk    : in  std_logic;   -- reloj del sistema
    x_n    : in  std_logic;   -- entrada binaria a la que deben eliminarse los rebotes (a baja en reposo)
    xdeb_n : out std_logic    -- salida que sique a la entrada pero sin rebotes
  );
  end component;
  
  component edgeDetector
  port (
    rst_n : in  std_logic;   -- reset asncrono del sistema (a baja)
    clk   : in  std_logic;   -- reloj del sistema
    x_n   : in  std_logic;   -- entrada binaria con flancos a detectar (a baja en reposo)
    xFall : out std_logic;   -- se activa durante 1 ciclo cada vez que detecta un flanco de subida en x
    xRise : out std_logic    -- se activa durante 1 ciclo cada vez que detecta un flanco de bajada en x
  );
  end component;
  
  component frequencySynthesizer
  generic (
    FREQ     : natural;                 -- frecuencia del reloj de entrada en KHz
    MODE     : string;                  -- modo del sintetizador de frecuencia "LOW" o "HIGH"
    MULTIPLY : natural range 2 to 32;   -- factor por el que multiplicar la frecuencia de entrada 
    DIVIDE   : natural range 1 to 32    -- divisor por el que dividir la frecuencia de entrada
  );
  port (
    clkIn  : in  std_logic;   -- reloj de entrada
    ready  : out std_logic;   -- indica si el reloj de salida es vlido
    clkOut : out std_logic    -- reloj de salida
  );
  end component;
  
  signal clk, rst_n : std_logic;
  signal ready, rstInit_n : std_logic;
  
  signal enterSync_n, enterDeb_n, enterFall : std_logic;
  signal switchesSync_n : std_logic_vector(7 downto 0);
  signal ldCode, eq, lock : std_logic;
  signal code : std_logic_vector(7 downto 0);
  signal tries : std_logic_vector(3 downto 0);
    
begin

  rstInit_n <= rstPb_n and ready;
  
  resetSyncronizer : synchronizer
    generic map ( STAGES => 2, INIT => '0' )
    port map ( rst_n => rstInit_n, clk => clk, x => '1', xSync => rst_n );
  
  -- Synthesizes a clock frequency of 30_000 Hz
  clkGenerator : frequencySynthesizer
    generic map ( FREQ => 50_000, MODE => "LOW", MULTIPLY => 3, DIVIDE => 5 )
    port map ( clkIn => osc, ready => ready, clkOut => clk );

  ------------------
  -- Process input signal enter_n
  enterSynchronizer : synchronizer
    generic map ( STAGES => 2, INIT => '1' )
    port map ( rst_n => rst_n, clk => clk, x => enter_n, xSync => enterSync_n ); 
   
  enterDebouncer : debouncer
    generic map ( FREQ => 30_000, BOUNCE => 50 )
    port map ( rst_n => rst_n, clk => clk, x_n => enterSync_n, xdeb_n => enterDeb_n );
   
  enterEdgeDetector : edgeDetector
    port map ( rst_n => rst_n, clk => clk, x_n => enterDeb_n, xFall => enterFall, xRise => open ); 
    
  -- Process input signals switches_n
  switchesSynchronizer : 
  for i in switches_n'range generate
  begin
    switchsynchronizer : synchronizer
      generic map ( STAGES => 2, INIT => '1' )
      port map ( rst_n => rst_n, clk => clk, x => switches_n(i), xSync => switchesSync_n(i) ); 
  end generate;

  ------------------
  -- Moore FSM implementation
  fsm:
  process (rst_n, clk, enterFall)
    type states is (initial, S3, S2, S1, S0); 
    variable state: states;
  begin 
    if state=initial and enterFall='1' then
      ldCode <= '1';
    else
      ldCode <= '0';
    end if;
    case state is
      when initial =>
        tries <= X"A";
        lock  <= '0';
      when S3 =>
        tries <= X"3";
        lock <= '1';
      when S2 =>
        tries <= X"2";
        lock <= '1';
      when S1 =>
        tries <= X"1";
        lock <= '1';
      when S0 =>
        tries <= X"C";
        lock <= '1';
    end case;
    if rst_n='0' then
      state := initial;
    elsif rising_edge(clk) then
      case state is
        when initial =>
          if enterFall='1' then
            state := S3;
          end if;
        when S3 =>
          if enterFall='1' and eq='1' then
            state := initial;
          elsif enterFall='1' and eq='0' then
            state := S2;
          end if;
        when S2 =>
          if enterFall='1' and eq='1' then 
            state := initial;
          elsif enterFall='1' and eq='0' then
            state := S1;
          end if;
        when S1 =>
          if enterFall='1' and eq='1' then 
            state := initial;
          elsif enterFall='1' and eq='0' then
            state := S0;
          end if;
        when S0 =>
            state := state;
      end case;
    end if;
  end process;  

  codeRegister :
  process (rst_n, clk)
  begin
    if rst_n='0' then
      code <= (others => '0');
    elsif rising_edge(clk) then
      if ldCode='1' then
        code <= not switchesSync_n;
      end if;
    end if;
  end process;
  
  comparator:
  eq <= '1' when code = (not switches_n) else '0';
  
--  comparator:
--  process (code, switches_n)
--  variable tmp : std_logic;
--  begin
--    eq <= tmp;
--    
--    tmp := '1';
--    for i in code'low to code'high loop
--      tmp := tmp and (code(i) xor (not switches_n(i)));
--    end loop;
--  end process;

  rigthConverter : bin2segs 
    port map (bin => tries, dp => '0', segs => upSegs);
  
  leds <= (7 downto 0 => lock);

end syn;
