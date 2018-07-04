---------------------------------------------------------------------
--
--  Fichero:
--    lab4.vhd  15/7/2015
--
--    (c) J.M. Mendias
--    Diseo Automtico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Propsito:
--    Laboratorio 4
--
--  Notas de diseo:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab4 is
  port
  (
    rstPb_n   : in  std_logic;
    osc       : in  std_logic;
    ps2Clk    : in  std_logic;
    ps2Data   : in  std_logic;
    leftSegs  : out std_logic_vector(7 downto 0);
    rightSegs : out std_logic_vector(7 downto 0);
    speaker   : out std_logic
  );
end lab4;

---------------------------------------------------------------------

use work.common.all;

architecture syn of lab4 is

  constant CLKFREQ : natural := 50_000_000;  -- frecuencia del reloj en MHz
  
  signal clk, rst_n : std_logic;

  signal dataRdy : std_logic;
  signal code, data : std_logic_vector(7 downto 0);
  signal ldCode : std_logic;
  signal halfPeriod : natural;
  signal speakerTFF, soundEnable: std_logic;

	signal aux: std_logic_vector(3 downto 0);
begin

  clk <= osc;
  
  resetSyncronizer : synchronizer
	generic map ( STAGES => 2, INIT => '0' )
	port map ( rst_n => '1', clk => clk, x => rstPb_n, xSync => rst_n );

  ------------------  
  
  ps2KeyboardInterface : ps2Receiver
    generic map ( REGOUTPUTS => false )
    port map ( rst_n => rst_n, clk => clk, dataRdy => dataRdy, data => data, ps2Clk => ps2Clk, ps2Data => ps2Data);

  codeRegister :
  process (rst_n, clk)
  begin
    if rst_n = '0' then
      code <= (others => '1');
    elsif rising_edge(clk) then
      if ldCode = '1' then
        code <= data;
      end if;
    end if; 
  end process;
  
  leftConverter : bin2segs 
    port map (bin => code(7 downto 4), dp => '0', segs => leftSegs);
    
  rigthConverter : bin2segs 
    port map (bin => code(3 downto 0), dp => '0', segs => rightSegs);
  
    
--  leftConverter : bin2segs 
--    port map (bin => code(7 downto 4), dp => '0', segs => leftSegs);
--  
--  aux <= "000" & ps2Data;
--  rigthConverter : bin2segs 
--    port map (bin => aux, dp => '0', segs => rightSegs);
	 
  halfPeriodROM :
  with code select
    halfPeriod <=
      CLKFREQ/(2*262) when X"1c",  -- A = Do
      CLKFREQ/(2*277) when X"1d",  -- W = Do#
      CLKFREQ/(2*298) when X"1b",  -- S = Re
      CLKFREQ/(2*311) when X"24",  -- E = Re#
      CLKFREQ/(2*330) when X"23",  -- D = Mi
      CLKFREQ/(2*349) when X"2b",  -- F = Fa
      CLKFREQ/(2*370) when X"2c",  -- T = Fa#
      CLKFREQ/(2*392) when X"34",  -- G = Sol
      CLKFREQ/(2*415) when X"35",  -- Y = Sol#
      CLKFREQ/(2*440) when X"33",  -- H = La
      CLKFREQ/(2*466) when X"3c",  -- U = La#
      CLKFREQ/(2*494) when X"3b",  -- J = Si
      CLKFREQ/(2*523) when X"42",  -- K = Do
      0 when others;    
    
  cycleCounter :
  process (rst_n, clk)
    variable count : natural;
  begin
    if rst_n = '0' then
      speakerTFF <= '0';
      count := 0;
    elsif rising_edge(clk) then
      if count = 0 then
        speakerTFF <= not speakerTFF;
        count := halfPeriod;
      else
        speakerTFF <= speakerTFF;
        count := count - 1;
      end if;
    end if; 
  end process;
  
  -- Moore FSM implementation
  fsm:
  process (rst_n, clk, dataRdy, data, code)
    type states is (S0, S1, S2, S3); 
    variable state: states;
  begin 
    if state = S0 and dataRdy = '1' and data /= X"f0" then
      ldCode <= '1';
    else
      ldCode <= '0';
    end if;
    case state is
      when S0 =>
        soundEnable <= '0';
      when S1 =>
        soundEnable <= '1';
      when S2 =>
        soundEnable <= '1';
      when S3 =>
        soundEnable <= '0';
    end case;
    if rst_n = '0' then
      state := S0;
    elsif rising_edge(clk) then
      case state is
        when S0 =>
          if dataRdy = '1' and data = X"f0" then
            state := S3;
          elsif dataRdy = '1' and data /= X"f0" then
            state := S1;
          end if;
        when S1 =>
          if dataRdy = '1' and data = X"f0" then
            state := S2;
          end if;
        when S2 =>
          if dataRdy = '1' and data = code then
            state := S0;
          elsif dataRdy = '1' and data /= code then
            state := S1;
          end if;
        when S3 =>
          if dataRdy = '1' then
            state := S0;
          end if;
      end case;
    end if;
  end process;
  
  speaker <= 
    speakerTFF when soundEnable = '1' else '0';
  
end syn;
