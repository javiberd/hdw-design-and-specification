----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Javier Berdecio Trigueros
-- 
-- Create Date:    14:57:48 05/22/2018 
-- Design Name: 
-- Module Name:    proyecto - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity proyecto is
  port ( 
    rstPb_n : in  std_logic;
    osc     : in  std_logic;
    ps2Clk  : in  std_logic;
    ps2Data : in  std_logic;
    hSync   : out std_logic;
    vSync   : out std_logic;
    RGB     : out std_logic_vector(8 downto 0)
  );
end proyecto;

---------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture Behavioral of proyecto is
  
  constant CLKFREQ : natural := 50_000_000;  -- frecuencia del reloj en MHz
  signal clk, rst_n : std_logic;
  
  constant NUMPLATFORMS : natural := 6;
  constant LENGTHPLATFORM : natural := 14;
  constant SEPPLATFORMS: natural := 18;
  type platformsArray is array (0 to NUMPLATFORMS-1) of unsigned(7 downto 0);
  
  -- Keyboard signals
  signal data: std_logic_vector(7 downto 0);
  signal dataRdy: std_logic;
  
  signal upP, downP, leftP, rightP, spcP: boolean;
  
  -- VGA signals
  signal color : std_logic_vector(2 downto 0);
  signal lineAux, pixelAux : std_logic_vector(9 downto 0);
  signal platform, board, player: std_logic;
  
  -- Game elements  
  signal playerOnPlatform, playerUnderPlatformColission: std_logic;
  signal gameOver, restart, move, movePlayer: boolean;
  signal xPlatforms : platformsArray;
  signal yPlatforms : platformsArray;
  
  signal line, yRight, yLeft, yPlayer: unsigned(7 downto 0);
  signal pixel, xPlayer: unsigned(7 downto 0);
  
  -- Random numbers
  signal random: std_logic_vector(79 downto 0);
  signal ldReg: std_logic;
  
  component lsfr
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
  end component;
  
begin

  randomGenerator: lsfr
  generic map ( WIDTH => 80 )
    port map ( rst_n => rstPb_n, clk => clk, ce => '1', ld => ldReg, seed => "10010101110111100101100101011101111001011001010111011110010110010101110111100101", random => random );


  clk <= osc;
  
  resetSyncronizer : synchronizer
    generic map ( STAGES => 2, INIT => '0' )
    port map ( rst_n => rstPb_n, clk => clk, x => '1', xSync => rst_n );
  
  ----------------------------------------------------------------------------------------------------
  -- Keyboard
  
  ps2KeyboardInterface : ps2Receiver
    generic map ( REGOUTPUTS => false )
    port map ( rst_n => rst_n, clk => clk, dataRdy => dataRdy, data => data, ps2Clk => ps2Clk, ps2Data => ps2Data );

  keyScanner:
  process( rst_n, clk )
    type states is (keyON, keyOFF);
    variable state : states;
  begin
    if rst_n='0' then
      state := keyON;
      upP <= false;    -- W
      downP <= false;  -- S
      leftP <= false;  -- A
      rightP <= false; -- D
      spcP <= false;   -- Space
    elsif rising_edge(clk) then
      if dataRdy='1' then
        case state is
          when keyON =>
            case data is
              when X"F0" => state := keyOFF;
              when X"1D" => upP <= true;
              when X"1B" => downP <= true;
              when X"1C" => leftP <= true;
              when X"23" => rightP <= true;
              
              when X"75" => upP <= true;
              when X"72" => downP <= true;
              when X"6B" => leftP <= true;
              when X"74" => rightP <= true;
              
              when X"29" => spcP <= true;
              when others => state := keyON;
            end case;
          when keyOFF =>
            state := keyON;
            case data is
              when X"1D" => upP <= false;
              when X"1B" => downP <= false;
              when X"1C" => leftP <= false;
              when X"23" => rightP <= false;
              
              when X"75" => upP <= false;
              when X"72" => downP <= false;
              when X"6B" => leftP <= false;
              when X"74" => rightP <= false;
              
              when X"29" => spcP <= false;
              when others => 
          end case;
        end case;
      end if;
    end if;
  end process;        
  
  ----------------------------------------------------------------------------------------------------
  -- VGA
  
  screenInteface: vgaInterface
    generic map ( FREQ => 50_000, SYNCDELAY => 0 )
    port map ( rst_n => rst_n, clk => clk, line => lineAux, pixel => pixelAux, R => color, G => color, B => color, hSync => hSync, vSync => vSync, RGB => RGB );

  pixel <= unsigned(pixelAux(9 downto 2));
  line <= unsigned(lineAux(9 downto 2));
  
  color <= "111" when platform='1' else
           "111" when board='1' else
           "101" when player='1' else
           "000";
  
  board <= '1' when pixel="00100000"-1 or pixel="00111111"+LENGTHPLATFORM+1 else '0';
  player <= '1' when pixel=xPlayer and line=yPlayer else '0';
  
  platformPaint:
  process(xPlayer, yPlayer, xPlatforms, yPlatforms)
    variable temp : std_logic_vector(NUMPLATFORMS-1 downto 0);
  begin
    if line=yPlatforms(0) and pixel>=xPlatforms(0) and pixel<=xPlatforms(0)+LENGTHPLATFORM then
      temp(0) := '1';
    else
      temp(0) := '0';
    end if;
    for i in 1 to NUMPLATFORMS-1 loop
        if (line=yPlatforms(i) and pixel>=xPlatforms(i) and pixel<=xPlatforms(i)+LENGTHPLATFORM) or temp(i-1)='1' then
          temp(i) := '1';
        else 
          temp(i) := '0';
        end if;
    end loop;
    platform <= temp(NUMPLATFORMS-1);
  end process;
  
  ----------------------------------------------------------------------------------------------------
  
  gameOver <= yPlayer=110;
  restart <= gameOver and spcP;
  
  ----------------------------------------------------------------------------------------------------
  -- Elements of the game
  
  pulseGen:
  process (rst_n, clk)
    constant maxValue : natural := CLKFREQ/25-1;
    variable count: natural range 0 to maxValue;
  begin
    if count=maxValue then
      move <= true;
      movePlayer <= true;
    elsif count=maxValue/4 then
      move <= false;
      movePlayer <= true;
    else
      move <= false;
      movePlayer <= false;
    end if;
    if rst_n='0' then
      count := 0;
    elsif rising_edge(clk) then
      if not gameOver then
        if count=maxValue then
          count := 0;
        else
          count := count + 1;
        end if;
      end if;
    end if;
  end process;
  
  ldSeedRegister:
  process (rst_n, clk)
  variable count: natural range 0 to 10;
  begin
    if rst_n='0' then
		count := 0;
		ldReg <= '1';
    elsif rising_edge(clk) then
      if count=10 then
        count := 10;
        ldReg <= '0';
      else 
        count := count + 1;
        ldReg <= '1';
      end if;
    end if;    
  end process;
 
  xPlatformsRegister:
  process (rst_n, clk)
  begin
    if rst_n='0' then
      for i in 0 to NUMPLATFORMS-1 loop
        if i=2 then
          xPlatforms(i) <= "001" & "00000";
        else
          xPlatforms(i) <= "001" & unsigned(random(4*(i+1) downto 4*i));
        end if;
      end loop;
    elsif rising_edge(clk) then
      if restart then
        for i in 0 to NUMPLATFORMS-1 loop
          if i=2 then
            xPlatforms(i) <= "001" & "00000";
          else
            xPlatforms(i) <= "001" & unsigned(random(4*(i+1) downto 4*i));
          end if;
        end loop;
      else
        if move then
          for i in 0 to NUMPLATFORMS-1 loop
            if yPlatforms(i)=110 then
              xPlatforms(i) <= "001" & unsigned(random(4*(i+1) downto 4*i));
            end if;
          end loop;
        end if;
      end if;
    end if; 
  end process;
  
  yPlatformsRegister:
  process (rst_n, clk)
  begin
    if rst_n='0' then
      for i in 0 to NUMPLATFORMS-1 loop
        yPlatforms(i) <= to_unsigned(i*SEPPLATFORMS, 8);
      end loop;
    elsif rising_edge(clk) then
      if restart then
        for i in 0 to NUMPLATFORMS-1 loop
          yPlatforms(i) <= to_unsigned(i*SEPPLATFORMS, 8);
        end loop;
      else
        if move then
          for i in 0 to NUMPLATFORMS-1 loop
            if yPlatforms(i)=110 then
              yPlatforms(i) <= (others => '0');
            else
              yPlatforms(i) <= yPlatforms(i) + 1;
            end if;
          end loop;
        end if;    
      end if;
    end if;    
  end process;
  
  xPlayerRegister:
  process (rst_n, clk)
    type sense is (left, right);
    variable dir: sense;
  begin
    if rst_n='0' then
      xPlayer <= to_unsigned(60, 8);
    elsif rising_edge(clk) then
      if restart then
        xPlayer <= to_unsigned(60, 8);
      elsif move then
        if leftP then
          if xPlayer="00100000" then
            xPlayer <= "00111111"+LENGTHPLATFORM;
          else
            xPlayer <= xPlayer - 1;
          end if;
        elsif rightP then
          if xPlayer="00111111"+LENGTHPLATFORM then
            xPlayer <= "00100000";
          else
            xPlayer <= xPlayer + 1;
          end if;
        else
          xPlayer <= xPlayer;
        end if;
      end if;
    end if; 
  end process;
  
  yPlayerRegister:
  process (rst_n, clk)
    type sense is (up, down);
    variable dir: sense;
    variable count: natural range 0 to 100;
  begin
    if rst_n='0' then
      yPlayer <= to_unsigned(2*17-1, 8);
      dir := down;
    elsif rising_edge(clk) then
      if restart then
        yPlayer <= to_unsigned(2*17-1, 8);
      elsif playerUnderPlatformColission='1' and movePlayer then
        dir := down;
        yPlayer <= yPlayer + 1;
      elsif playerOnPlatform='1' and upP and movePlayer then
        dir := up;
        count := 1;
        yPlayer <= yPlayer - 2;
      elsif playerUnderPlatformColission='0' and dir=up and count<SEPPLATFORMS and movePlayer then
        count := count + 1;
        yPlayer <= yPlayer - 1;
      elsif dir=up and count=SEPPLATFORMS and movePlayer then
        dir := down;
        yPlayer <= yPlayer + 1;
      elsif (playerOnPlatform='1' and move) or (playerOnPlatform='0' and movePlayer) then
        yPlayer <= yPlayer + 1;
      end if;
    end if;   
  end process;
  
  -- Check if player is on platform
  playerOnPlatformSignal:
  process(xPlayer, yPlayer, xPlatforms, yPlatforms)
    variable temp : std_logic_vector(NUMPLATFORMS-1 downto 0);
  begin
    if yPlayer+1=yPlatforms(0) and xPlayer>=xPlatforms(0) and xPlayer<=xPlatforms(0)+LENGTHPLATFORM then
      temp(0) := '1';
    else
      temp(0) := '0';
    end if;
    for i in 1 to NUMPLATFORMS-1 loop
        if (yPlayer+1=yPlatforms(i) and xPlayer>=xPlatforms(i) and xPlayer<=xPlatforms(i)+LENGTHPLATFORM) or temp(i-1)='1' then
          temp(i) := '1';
        else 
          temp(i) := '0';
        end if;
    end loop;
    playerOnPlatform <= temp(NUMPLATFORMS-1);
  end process;
  
  -- Check if player is just under the platform
  playerUnderPlatformColissionSignal:
  process(xPlayer, yPlayer, xPlatforms, yPlatforms)
    variable temp : std_logic_vector(NUMPLATFORMS-1 downto 0);
  begin
    if yPlayer-1=yPlatforms(0) and xPlayer>=xPlatforms(0) and xPlayer<=xPlatforms(0)+LENGTHPLATFORM then
      temp(0) := '1';
    else
      temp(0) := '0';
    end if;
    for i in 1 to NUMPLATFORMS-1 loop
        if (yPlayer-1=yPlatforms(i) and xPlayer>=xPlatforms(i) and xPlayer<=xPlatforms(i)+LENGTHPLATFORM) or temp(i-1)='1' then
          temp(i) := '1';
        else 
          temp(i) := '0';
        end if;
    end loop;
    playerUnderPlatformColission <= temp(NUMPLATFORMS-1);
  end process;

end Behavioral;

