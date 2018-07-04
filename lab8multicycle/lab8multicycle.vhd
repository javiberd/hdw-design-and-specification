---------------------------------------------------------------------
--
--  Fichero:
--    lab8multicycle.vhd  22/3/2017
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Laboratorio 8 versión multiciclo
--
--  Notas de diseño:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab8multicycle is
  port(
    rstPb_n    : in    std_logic;
    osc        : in    std_logic;
    filterOn_n : in    std_logic;
    mclk       : out   std_logic;
    sclk       : out   std_logic;
    lrck       : out   std_logic;
    sdti       : out   std_logic;
    sdto       : in    std_logic
  );
end lab8multicycle;

-------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of lab8multicycle is

  signal clk, rst_n : std_logic;

  signal filterOnSync_n, filterOnDeb_n : std_logic;

  signal inSample, outSample : std_logic_vector (15 downto 0);
  signal inSampleRdy, leftChannel, newLeftSample, newRightSample : std_logic;
  
  signal outRegLeftSample, outFilterLeftSample : std_logic_vector (15 downto 0);
  signal outRegRightSample, outFilterRightSample : std_logic_vector (15 downto 0);
    
  component multicycleNotchFilter is
    generic (
      WL : natural;  -- anchura de la muestra
      QM : natural;  -- número de bits decimales en la muestra
      FS : real;     -- frecuencia de muestreo
      F0 : real      -- frecuencia de corte
    );
    port(
      rst_n     : in    std_logic;  -- reset asíncrono del sistema (a baja)
      clk       : in    std_logic;  -- reloj del sistema
      newSample : in    std_logic;  -- indica si existe una nueva muestra que procesar
      inSample  : in    std_logic_vector(WL-1 downto 0);  -- muestra de entrada
      outSample : out   std_logic_vector(WL-1 downto 0)   -- muestra de salida
    );
  end component;

begin

  clk <= osc;
  
  resetSyncronizer : synchronizer
    generic map ( STAGES => 2, INIT => '0' )
    port map ( rst_n => rstPb_n, clk => clk, x => '1', xSync => rst_n );

  ------------------  

  filterOnSynchronizer : synchronizer
    generic map ( STAGES => 2, INIT => '1' )
    port map ( rst_n => rst_n, clk => clk, x => filterOn_n, xSync => filterOnSync_n );

  filterOnDebouncer : debouncer
    generic map ( FREQ => 50_000, BOUNCE => 50 )
    port map ( rst_n => rst_n, clk => clk, x_n => filterOnSync_n, xDeb_n => filterOnDeb_n );
       
  ------------------  
 
  outSampleMux :
  process ( filterOnDeb_n, leftChannel, outFilterLeftSample, outFilterRightSample, outRegLeftSample, outRegRightSample )
  begin
    if( filterOnDeb_n='0' ) then
      if( leftChannel='1' ) then
        outSample <= std_logic_vector(outFilterLeftSample);
      else
        outSample <= std_logic_vector(outFilterRightSample);
      end if;
    else
      if( leftChannel='1' ) then
        outSample <= std_logic_vector(outRegLeftSample);
      else
        outSample <= std_logic_vector(outRegRightSample);
      end if;
    end if;
  end process;    
 
  ------------------  

  inLeftSampleRegister :
  process (rst_n, clk)
  begin
    if rst_n='0' then
      outRegLeftSample <= (others => '0');
    elsif rising_edge(clk) then
      if newLeftSample='1' then
        outRegLeftSample <= inSample;
      end if;
    end if; 
  end process;  
  
  inRightSampleRegister :
  process (rst_n, clk)
  begin
    if rst_n='0' then
      outRegRightSample <= (others => '0');
    elsif rising_edge(clk) then
      if newRightSample='1' then
        outRegRightSample <= inSample;
      end if;
    end if; 
  end process;  
  
  ------------------
  
  leftFilter : multicycleNotchFilter
    generic map ( WL =>  16, QM => 14, FS => 48828.0, F0 => 800.0 )
    port map ( rst_n => rst_n, clk => clk, newSample => newLeftSample, inSample => inSample, outSample => outFilterLeftSample );
    
  rightFilter : multicycleNotchFilter
    generic map ( WL =>  16, QM => 14, FS => 48828.0, F0 => 800.0 )
    port map ( rst_n => rst_n, clk => clk, newSample => newRightSample, inSample => inSample, outSample => outFilterRightSample );

  newLeftSample <= inSampleRdy and leftChannel;
  
  newRightSample <= inSampleRdy and not leftChannel;
  
  ------------------  

  codecInterface : iisInterface
    generic map( WIDTH => 16 ) 
    port map( 
      rst_n => rst_n, clk => clk, 
      leftChannel => leftChannel, inSample => inSample, inSampleRdy => inSampleRdy, outSample => outSample, outSampleRqt => open,
      mclk => mclk, sclk => sclk, lrck => lrck, sdti => sdti, sdto => sdto
    );
   
end syn;

