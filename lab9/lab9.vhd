---------------------------------------------------------------------
--
--  Fichero:
--    lab9.vhd  27/4/2017
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Laboratorio 9
--
--  Notas de diseño:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab9 is
  port(
    rstPb_n   : in    std_logic;
    osc       : in    std_logic;
    rec_n     : in    std_logic;
    play_n    : in    std_logic;
    incVol_n  : in    std_logic;
    decVol_n  : in    std_logic;
    led       : out   std_logic;
    upSegs    : out   std_logic_vector(7 downto 0);
    leftSegs  : out   std_logic_vector(7 downto 0);
    rightSegs : out   std_logic_vector(7 downto 0);
    mclk      : out   std_logic;
    sclk      : out   std_logic;
    lrck      : out   std_logic;
    sdti      : out   std_logic;
    sdto      : in    std_logic;
    clkOutFb  : in    std_logic;
    clkOut    : out   std_logic;
    cke       : out   std_logic;
    cs_n      : out   std_logic;
    ras_n     : out   std_logic;
    cas_n     : out   std_logic;
    we_n      : out   std_logic;
    ba        : out   std_logic_vector( 1 downto 0);
    sAddr     : out   std_logic_vector(12 downto 0);
    sData     : inout std_logic_vector(15 downto 0);
    dqmh      : out   std_logic;
    dqml      : out   std_logic
  );
end lab9;

-------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of lab9 is

  constant SAMPLESNUM : natural := 48_828*2*60; 

  signal ready, rstInit_n : std_logic;
  signal clk, rst_n : std_logic;

  signal recSync_n, recDeb_n, recFall          : std_logic;
  signal playSync_n, playDeb_n, playFall       : std_logic;
  signal incVolSync_n, incVolDeb_n, incVolFall : std_logic;
  signal decVolSync_n, decVolDeb_n, decVolFall : std_logic;
  
  signal inSample, outSample       : std_logic_vector (15 downto 0);
  signal inSampleRdy, outSampleRqt : std_logic;
 
  signal wr, rd, opBegun   : std_logic; 
  signal hDIn, hDOut       : std_logic_vector(15 downto 0);
  signal hAddr             : std_logic_vector(23 downto 0); 
  signal recAddr, playAddr : unsigned (23 downto 0);

  signal vol                   : unsigned(3 downto 0);
  signal secHigh, secLow       : unsigned (3 downto 0);
  
  type states is (initial, recording, writeSample, waiting, playing, readSample); 
  signal state : states;
    
begin


  rstInit_n <= rstPb_n and ready;
  
  resetSyncronizer : synchronizer
    generic map ( STAGES => 2, INIT => '0' )
    port map ( rst_n => rstInit_n, clk => clk, x => '1', xSync => rst_n );
   
  clkDesckewer : desckewer
    generic map ( FREQ => 50_000 )
    port map ( clkIn => osc, intClk => clk, extClk => clkOut, extClkFb => clkOutFb, ready => ready );
        
  ------------------  
      
  recSynchronizer : synchronizer
    generic map ( STAGES => 2, INIT => '1' )
    port map ( rst_n => rst_n, clk => clk, x => rec_n, xSync => recSync_n );

  recDebouncer : debouncer
    generic map ( FREQ => 50_000, BOUNCE => 50 )
    port map ( rst_n => rst_n, clk => clk, x_n => recSync_n, xDeb_n => recDeb_n );
   
  recEdgeDetector : edgeDetector
    port map ( rst_n => rst_n, clk => clk, x_n => recDeb_n, xFall => recFall, xRise => open );

  playSynchronizer : synchronizer
    generic map ( STAGES => 2, INIT => '1' )
    port map ( rst_n => rst_n, clk => clk, x => play_n, xSync => playSync_n );

  playDebouncer : debouncer
    generic map ( FREQ => 50_000, BOUNCE => 50 )
    port map ( rst_n => rst_n, clk => clk, x_n => playSync_n, xDeb_n => playDeb_n );
   
  playEdgeDetector : edgeDetector
    port map ( rst_n => rst_n, clk => clk, x_n => playDeb_n, xFall => playFall, xRise => open );
    
  incVolSynchronizer : synchronizer
    generic map ( STAGES => 2, INIT => '1' )
    port map ( rst_n => rst_n, clk => clk, x => incVol_n, xSync => incVolSync_n );

  incVolDebouncer : debouncer
    generic map ( FREQ => 50_000, BOUNCE => 50 )
    port map ( rst_n => rst_n, clk => clk, x_n => incVolSync_n, xDeb_n => incVolDeb_n );
   
  incVolEdgeDetector : edgeDetector
    port map ( rst_n => rst_n, clk => clk, x_n => incVolDeb_n, xFall => incVolFall, xRise => open );

  decVolSynchronizer : synchronizer
    generic map ( STAGES => 2, INIT => '1' )
    port map ( rst_n => rst_n, clk => clk, x => decVol_n, xSync => decVolSync_n );

  decVolDebouncer : debouncer
    generic map ( FREQ => 50_000, BOUNCE => 50 )
    port map ( rst_n => rst_n, clk => clk, x_n => decVolSync_n, xDeb_n => decVolDeb_n );
   
  decVolEdgeDetector : edgeDetector
    port map ( rst_n => rst_n, clk => clk, x_n => decVolDeb_n, xFall => decVolFall, xRise => open );

  ------------------  

  codecInterface : iisInterface
    generic map( WIDTH => 16 ) 
    port map( 
      rst_n => rst_n, clk => clk, 
      leftChannel => open, inSample => inSample, inSampleRdy => inSampleRdy, outSample => outSample, outSampleRqt => outSampleRqt,
      mclk => mclk, sclk => sclk, lrck => lrck, sdti => sdti, sdto => sdto
    );

  volShifter :
  outSample <= "1"               & hDOut(15 downto 1)  when vol=1  and hDOut(15)='1' else
               "0"               & hDOut(15 downto 1)  when vol=1  and hDOut(15)='0' else
               "11"              & hDOut(15 downto 2)  when vol=2  and hDOut(15)='1' else
               "00"              & hDOut(15 downto 2)  when vol=2  and hDOut(15)='0' else
               "111"             & hDOut(15 downto 3)  when vol=3  and hDOut(15)='1' else
               "000"             & hDOut(15 downto 3)  when vol=3  and hDOut(15)='0' else
               "1111"            & hDOut(15 downto 4)  when vol=4  and hDOut(15)='1' else
               "0000"            & hDOut(15 downto 4)  when vol=4  and hDOut(15)='0' else
               "11111"           & hDOut(15 downto 5)  when vol=5  and hDOut(15)='1' else
               "00000"           & hDOut(15 downto 5)  when vol=5  and hDOut(15)='0' else
               "111111"          & hDOut(15 downto 6)  when vol=6  and hDOut(15)='1' else
               "000000"          & hDOut(15 downto 6)  when vol=6  and hDOut(15)='0' else
               "1111111"         & hDOut(15 downto 7)  when vol=7  and hDOut(15)='1' else
               "0000000"         & hDOut(15 downto 7)  when vol=7  and hDOut(15)='0' else
               "11111111"        & hDOut(15 downto 8)  when vol=8  and hDOut(15)='1' else
               "00000000"        & hDOut(15 downto 8)  when vol=8  and hDOut(15)='0' else
               "111111111"       & hDOut(15 downto 9)  when vol=9  and hDOut(15)='1' else
               "000000000"       & hDOut(15 downto 9)  when vol=9  and hDOut(15)='0' else
               "1111111111"      & hDOut(15 downto 10) when vol=10 and hDOut(15)='1' else
               "0000000000"      & hDOut(15 downto 10) when vol=10 and hDOut(15)='0' else
               "11111111111"     & hDOut(15 downto 11) when vol=11 and hDOut(15)='1' else
               "00000000000"     & hDOut(15 downto 11) when vol=11 and hDOut(15)='0' else
               "111111111111"    & hDOut(15 downto 12) when vol=12 and hDOut(15)='1' else
               "000000000000"    & hDOut(15 downto 12) when vol=12 and hDOut(15)='0' else
               "1111111111111"   & hDOut(15 downto 13) when vol=13 and hDOut(15)='1' else
               "0000000000000"   & hDOut(15 downto 13) when vol=13 and hDOut(15)='0' else
               "11111111111111"  & hDOut(15 downto 14) when vol=14 and hDOut(15)='1' else
               "00000000000000"  & hDOut(15 downto 14) when vol=14 and hDOut(15)='0' else
               "111111111111111" & hDOut(15 downto 15) when vol=15 and hDOut(15)='1' else
               "000000000000000" & hDOut(15 downto 15) when vol=15 and hDOut(15)='0' else
               hDOut(15 downto 0);

  hDIn  <= inSample; 
  hAddr <= std_logic_vector(recAddr) when wr='1' else std_logic_vector(playAddr);
  wr    <= '1' when state=writeSample else '0';
  rd    <= '1' when state=readSample else '0';

  ram : sdramController
    generic map(
      FREQ => 50_000, PIPE_EN => false, MAX_NOP => 10_000, MULTIPLE_ACTIVE_ROWS => false, ENABLE_REFRESH => true, 
      DATA_WIDTH => 16, NROWS => 8192, NCOLS => 512, HADDR_WIDTH => 24, SADDR_WIDTH => 13
    )
    port map(
      clk => clk, lock => ready, rst => not(rst_n), 
      rd => rd, wr => wr, hAddr => hAddr, hDIn => hDIn, hDOut => hDOut, 
      rdPending => open, opBegun => opBegun, earlyOpBegun => open, rdDone => open, done => open,
      cke => cke, ce_n => cs_n, ras_n => ras_n, cas_n => cas_n, we_n => we_n, ba => ba, sAddr => sAddr, sData => sData, dqmh => dqmh, dqml => dqml
    );
    
  fsmd :
  process (rst_n, clk)
  begin
    if rst_n='0' then
      recAddr  <= (others => '0');
      playAddr <= (others => '0');
      state    <= initial;
    elsif rising_edge(clk) then
      case state is
        when initial =>
          recAddr  <= (others => '0');
          playAddr <= (others => '0');
          if recFall='1' then
            state <= recording;
          end if;
        when recording =>
          if recFall='1' or (secHigh=6 and secLow=0) then
            state <= waiting;
          elsif inSampleRdy='1' then
            recAddr <= recAddr + 1;
            state <= writeSample;
          end if;
        when writeSample =>
            if opBegun='1' then
              state <= recording;
            end if;
        when waiting =>
          if recFall='1' then
            recAddr  <= (others => '0');
            state <= recording;
          elsif playFall='1' then
            playAddr <= (others => '0');
            state <= playing;
          end if;
        when playing =>
          if recFall='1' or recAddr=playAddr then
            state <= waiting;
          else
            playAddr <= playAddr + 1;
            state <= readSample;
          end if;
        when readSample =>
        if outSampleRqt='1' then
            state <= playing;
        end if;
      end case;
    end if; 
  end process;

  ------------------

  volCounter :
  process (rst_n, clk)
  begin
    if rst_n='0' then
      vol <= (others => '0');
    elsif rising_edge(clk) then
      if incVolFall='1' then
        if vol<15 then
          vol <= vol + 1;
        end if;
      elsif decVolFall='1' then
        if vol>0 then
          vol <= vol - 1;
        end if;
      end if;
    end if; 
  end process;
    
  secCounter :
  process (rst_n, clk)
    constant MAXVALUE : natural := 50_000_000-1;
    variable count, countReg : natural range 0 to MAXVALUE;
    variable secHighReg, secLowReg : unsigned(3 downto 0);
  begin
    secHigh <= secHighReg;
    secLow <= secLowReg;
    if rst_n='0' then
      countReg   := 0;
      secHighReg := (others => '0');
      secLowReg  := (others => '0');
    elsif rising_edge(clk) then
      if state=initial or state=waiting then
        countReg   := 0;
        secHighReg := (others => '0');
        secLowReg  := (others => '0');
      else
        if countReg=MAXVALUE then
          countReg := 0;
          --Aumentamos un segundo
          --Caso de que el contador de unidades este en 9 aumentamos el contador de decimas y reinicializamos
          if secLowReg="1001" then   
            secLowReg := (others => '0');
            --Caso de que el contador de decenas este a 9 reiniciamos contador
            if secHighReg="1001" then 
              secHighReg := (others => '0');
            --Caso normal de aumentar el contador de decenas
            else
              secHighReg := secHighReg + 1;
            end if;
          --Caso normal de aumentar el contador de unidades
          else
            secLowReg := secLowReg + 1;
          end if;
        else
          countReg := countReg + 1;
        end if;
      end if;
    end if;
  end process;
 
  ------------------ 

  led <= '1' when state=recording or state=writeSample else '0';

  upConverter : bin2segs 
    port map ( bin => std_logic_vector(vol), dp => '0', segs => upSegs );
  
  leftConverter : bin2segs 
    port map ( bin => std_logic_vector(secHigh), dp => '0', segs => leftSegs );
  
  rigthConverter : bin2segs 
    port map ( bin => std_logic_vector(secLow), dp => '0', segs => rightSegs );

end syn;
