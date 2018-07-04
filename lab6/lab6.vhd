---------------------------------------------------------------------
--
--  Fichero:
--    lab6.vhd  15/7/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Laboratorio 6
--
--  Notas de diseño:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab6 is
  port ( 
    rstPb_n : in  std_logic;
    osc     : in  std_logic;
    ps2Clk  : in  std_logic;
    ps2Data : in  std_logic;
    hSync   : out std_logic;
    vSync   : out std_logic;
    RGB     : out std_logic_vector(8 downto 0)
  );
end lab6;

---------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of lab6 is

  constant CLKFREQ : natural := 50_000_000;  -- frecuencia del reloj en MHz

  signal clk, rst_n : std_logic;

  signal data: std_logic_vector(7 downto 0);
  signal dataRdy: std_logic;
  signal qP, aP, pP, lP, spcP: boolean;
  
  signal color : std_logic_vector(2 downto 0);
  
  signal campoJuego, raquetaDer, raquetaIzq, pelota: std_logic;
  
  signal mover, finPartida, reiniciar: boolean;

  signal lineAux, pixelAux : std_logic_vector(9 downto 0);
  
  signal line, yRight, yLeft, yBall: unsigned(7 downto 0);
  signal pixel, xBall: unsigned(7 downto 0);
  
begin

  clk <= osc;
  
  resetSyncronizer : synchronizer
    generic map ( STAGES => 2, INIT => '0' )
    port map ( rst_n => rstPb_n, clk => clk, x => '1', xSync => rst_n );

  ------------------  

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
      qP <= false;
      aP <= false;
      pP <= false;
      lP <= false;
      spcP <= false;
    elsif rising_edge(clk) then
      if dataRdy='1' then
        case state is
          when keyON =>
            case data is
              when X"F0" => state := keyOFF;
              when X"15" => qP <= true;
              when X"1C" => aP <= true;
              when X"4D" => pP <= true;
              when X"4B" => lP <= true;
              when X"29" => spcP <= true;
              when others => state := keyON;
            end case;
          when keyOFF =>
            state := keyON;
            case data is
              when X"15" => qP <= false;
              when X"1C" => aP <= false;
              when X"4D" => pP <= false;
              when X"4B" => lP <= false;
              when X"29" => spcP <= false;
              when others => 
          end case;
        end case;
      end if;
    end if;
  end process;        

------------------  

  screenInteface: vgaInterface
    generic map ( FREQ => 50_000, SYNCDELAY => 0 )
    port map ( rst_n => rst_n, clk => clk, line => lineAux, pixel => pixelAux, R => color, G => color, B => color, hSync => hSync, vSync => vSync, RGB => RGB );

  pixel <= unsigned(pixelAux(9 downto 2));
  line <= unsigned(lineAux(9 downto 2));
  
  
  color <= "111" when raquetaIzq='1' else
           "111" when raquetaDer='1' else
           "111" when pelota='1' else
           "111" when campoJuego='1' else
           "000";
  

------------------
 
  campoJuego <= '1' when (line=8) or (line=111) or 
                  (pixel=79 and ((line > 8 and line <= 16) or (line > 24 and line <= 32) or (line > 40 and line <= 48) or (line > 56 and line <= 64) or (line > 72 and line <= 80) or
                  (line > 88 and line <= 96) or (line >= 104 and line <= 111))) else '0';
  raquetaIzq <= '1' when (pixel=8 and line>=yLeft and line<=yLeft+16) else '0'; 
  raquetaDer <= '1' when (pixel=151 and line>=yRight and line<=yRight+16) else '0'; 
  pelota     <= '1' when (line=yBall and pixel=xBall) else '0'; 

------------------

  finPartida <= xBall=0 or xBall=159; --xBall > algo o xBall < principioPantalla
  reiniciar <= finPartida and spcP;   
  
------------------
  
  pulseGen:
  process (rst_n, clk)
    constant maxValue : natural := CLKFREQ/50-1;
    variable count: natural range 0 to maxValue;
  begin
    if count=maxValue then
      mover <= true;
    else
      mover <= false;
    end if;
    if rst_n='0' then
      count := 0;
    elsif rising_edge(clk) then
      if not finPartida then
        if count=maxValue then
          count := 0;
        else
          count := count + 1;
        end if;
      end if;
    end if;
  end process;    
        
------------------

  yRightRegister:
  process (rst_n, clk)
  begin
    if rst_n='0' then
      yRight <= X"09";
    elsif rising_edge(clk) then
      if reiniciar then
        yRight <= X"09";
      elsif mover then
        if pP and yRight>9 then
          yRight <= yRight - 2;
        elsif lP and yRight<94 then
          yRight <= yRight + 2;
        end if;
      end if;
    end if;
  end process;
  
  yLeftRegister:
  process (rst_n, clk)
  begin
    if rst_n='0' then
      yLeft <= X"09";
    elsif rising_edge(clk) then
      if reiniciar then
        yLeft <= X"09";
      elsif mover then
        if qP and yLeft>9 then
            yLeft <= yLeft - 2;
        elsif aP and yLeft<94 then
            yLeft <= yLeft + 2;
        end if;
      end if;
    end if;
  end process;
  
------------------
  
  xBallRegister:
  process (rst_n, clk)
    type sense is (left, right);
    variable dir: sense;
  begin
    if rst_n='0' then
      xBall <= to_unsigned(79, 8);
      dir := right;
    elsif rising_edge(clk) then
      if reiniciar then
        xBall <= to_unsigned(79, 8);
      elsif mover then
        if dir=right then
          if xBall=150 and yBall>=yRight and yBall<=yRight+16 then --choque paleta derecha
            dir := left;
            xBall <= xBall - 1;
          else
            xBall <= xBall + 1;
          end if;
        else
          if xBall=9 and yBall>=yLeft and yBall<=yLeft+16 then  --choque paleta izquierda
            dir := right;
            xBall <= xBall + 1;
          else
            xBall <= xBall - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  yBallRegister:
  process (rst_n, clk)
    type sense is (up, down);
    variable dir: sense;
  begin
    if rst_n='0' then
      yBall <= to_unsigned(59, 8);
      dir := up;
    elsif rising_edge(clk) then
      if reiniciar then
        yBall <= to_unsigned(59, 8);
      elsif mover then
        if dir=up then
          if yBall=9 then --choque pared superior
            dir := down;
            yBall <= yBall + 1;
          else
            yBall <= yBall - 1;
          end if;
        else
          if yBall=110 then --choque pared inferior
            dir := up;
            yBall <= yBall - 1;
          else
            yBall <= yBall + 1;
          end if;
        end if;
      end if;
    end if;    
  end process;

end syn;

