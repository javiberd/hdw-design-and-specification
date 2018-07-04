---------------------------------------------------------------------
--
--  Fichero:
--    lab7.vhd  4/11/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Laboratorio 7
--
--  Notas de diseño:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab7 is
  port ( 
    rstPb_n : in  std_logic;
    osc     : in  std_logic;
    ps2Clk  : in  std_logic;
    ps2Data : in  std_logic;
    hSync   : out std_logic;
    vSync   : out std_logic;
    RGB     : out std_logic_vector(8 downto 0)
  );
end lab7;

---------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of lab7 is

  constant COLSxLINE  : natural := 80;
  constant ROWSxFRAME : natural := 30;
 
  signal clk, rst_n : std_logic;
 
  signal data: std_logic_vector (7 downto 0);
  signal dataRdy: std_logic;

  signal x : unsigned (log2(COLSxLINE)-1 downto 0);
  signal y : unsigned (log2(ROWSxFRAME)-1 downto 0);
  
  signal shiftP, capsOn : boolean;
  
  signal char : std_logic_vector (7 downto 0);
  signal charRdy : std_logic;
  
  signal clear, newLine : std_logic;
  
begin

  clk <= osc;
  
  resetSyncronizer : synchronizer
    generic map ( STAGES => 2, INIT => '0' )
    port map ( rst_n => rstPb_n, clk => clk, x => '1', xSync => rst_n );

  --------------  

  ps2KeyboardInterface : ps2Receiver
    generic map ( REGOUTPUTS => true )
    port map ( rst_n => rst_n, clk => clk, dataRdy => dataRdy, data => data, ps2Clk => ps2Clk, ps2Data => ps2Data );
    
 
  keyScanner:
  process (rst_n, clk)
    type states is (keyON, keyOFF);
    variable state : states;
  begin
    if rst_n='0' then
      state   := keyON;
      shiftP  <= false; --12
      capsOn  <= false; --58
      charRdy <= '0'; 
		  newLine <= '0'; --5A ENTER
      clear   <= '0'; --76 ESC
    elsif rising_edge(clk) then
      charRdy <= '0';
      newLine <= '0';
      clear <= '0';
      if dataRdy='1' then
        case state is
          when keyON =>	
            case data is
              when X"F0" => state := keyOFF; charRdy <= '0';
              when X"12" => shiftP <= true; charRdy <= '0';
              when X"59" => shiftP <= true; charRdy <= '0';
              when X"58" => capsON <= not capsON; charRdy <= '0'; --CAPS LOCK
              when X"5A" => newLine <= '1'; charRdy <= '0'; --ENTER
              when X"76" => clear <= '1'; charRdy <= '0';   --ESC
              when others => charRdy <= '1'; state := keyON;
            end case;
          when keyOFF =>
              state := keyON;
              case data is
              when X"12" => shiftP <= false; charRdy <= '0';
              when X"59" => shiftP <= false; charRdy <= '0';
              when X"58" => charRdy <= '0';
              when X"5A" => newLine <= '0'; charRdy <= '0';
              when X"76" => clear <= '0'; charRdy <= '0'; --ESC
              when others => charRdy <= '0';
            end case;
        end case;   
      end if;
    end if;
  end process;

      
  scanCode2Ascii :
  process (shiftP, data, capsOn)
  begin
    if shiftP or capsOn then
      case data is
        when X"16" => char <= X"21";    -- !
        when X"1e" => char <= X"22";    -- "
        when X"26" => char <= X"b7";    -- ·
        when X"25" => char <= X"24";    -- $
        when X"2e" => char <= X"25";    -- %
        when X"36" => char <= X"26";    -- &
        when X"3d" => char <= X"2f";    -- /
        when X"3e" => char <= X"28";    -- (
        when X"46" => char <= X"29";    -- )
        when X"45" => char <= X"3d";    -- =
        when X"4e" => char <= X"3f";    -- ?
        when X"55" => char <= X"bf";    -- ¿
        when X"15" => char <= X"51";    -- Q
        when X"1d" => char <= X"57";    -- W
        when X"24" => char <= X"45";    -- E
        when X"2d" => char <= X"52";    -- R
        when X"2c" => char <= X"54";    -- T
        when X"35" => char <= X"59";    -- Y
        when X"3c" => char <= X"55";    -- U
        when X"43" => char <= X"49";    -- I
        when X"44" => char <= X"4f";    -- O
        when X"4d" => char <= X"50";    -- P
        when X"54" => char <= X"5e";    -- ^
        when X"5b" => char <= X"2a";    -- *
        when X"1c" => char <= X"41";    -- A
        when X"1b" => char <= X"53";    -- S
        when X"23" => char <= X"44";    -- D
        when X"2b" => char <= X"46";    -- F
        when X"34" => char <= X"47";    -- G
        when X"33" => char <= X"48";    -- H
        when X"3b" => char <= X"4a";    -- J
        when X"42" => char <= X"4b";    -- K
        when X"4b" => char <= X"4c";    -- L
        when X"4c" => char <= X"d1";    -- Ñ
        when X"52" => char <= X"a8";    -- ¨
        when X"1a" => char <= X"5a";    -- Z
        when X"22" => char <= X"58";    -- X
        when X"21" => char <= X"43";    -- C
        when X"2a" => char <= X"56";    -- V
        when X"32" => char <= X"42";    -- B
        when X"31" => char <= X"4e";    -- N
        when X"3a" => char <= X"4d";    -- M
        when X"41" => char <= X"3b";    -- ;
        when X"49" => char <= X"3a";    -- :
        when X"4a" => char <= X"5f";    -- _
        when X"29" => char <= X"20";    -- space
        when others => char <= X"7f";   -- invalido;
      end case;
    else
      case data is
        when X"16" => char <= X"31";    -- 1
        when X"1e" => char <= X"32";    -- 2
        when X"26" => char <= X"33";    -- 3
        when X"25" => char <= X"34";    -- 4
        when X"2e" => char <= X"35";    -- 5
        when X"36" => char <= X"36";    -- 6
        when X"3d" => char <= X"37";    -- 7
        when X"3e" => char <= X"38";    -- 8
        when X"46" => char <= X"39";    -- 9
        when X"45" => char <= X"30";    -- 0
        when X"4e" => char <= X"27";    -- '
        when X"55" => char <= X"a1";    -- ¡ 
        when X"15" => char <= X"71";    -- q
        when X"1d" => char <= X"77";    -- w
        when X"24" => char <= X"65";    -- e
        when X"2d" => char <= X"72";    -- r
        when X"2c" => char <= X"74";    -- t
        when X"35" => char <= X"79";    -- y
        when X"3c" => char <= X"75";    -- u
        when X"43" => char <= X"69";    -- i
        when X"44" => char <= X"6f";    -- o
        when X"4d" => char <= X"70";    -- p
        when X"54" => char <= X"60";    -- `
        when X"5b" => char <= X"2b";    -- +
        when X"1c" => char <= X"61";    -- a
        when X"1b" => char <= X"73";    -- s
        when X"23" => char <= X"64";    -- d
        when X"2b" => char <= X"66";    -- f
        when X"34" => char <= X"67";    -- g
        when X"33" => char <= X"68";    -- h
        when X"3b" => char <= X"6a";    -- j
        when X"42" => char <= X"6b";    -- k
        when X"4b" => char <= X"6c";    -- l
        when X"4c" => char <= X"f1";    -- ñ 
        when X"52" => char <= X"b4";    -- ´
        when X"1a" => char <= X"7a";    -- z
        when X"22" => char <= X"78";    -- x
        when X"21" => char <= X"63";    -- c
        when X"2a" => char <= X"76";    -- v
        when X"32" => char <= X"62";    -- b
        when X"31" => char <= X"6e";    -- n
        when X"3a" => char <= X"6d";    -- m
        when X"41" => char <= X"2c";    -- ,
        when X"49" => char <= X"2e";    -- .
        when X"4a" => char <= X"2d";    -- -
        when X"29" => char <= X"20";    -- space
        when others => char <= X"7f";   -- invalido;
      end case;
    end if;
  end process;
   
  ------------------     
  
  screenInterface: vgaTxtInterface 
    generic map ( FREQ => 50_000 )
    port map ( rst_n => rst_n, clk => clk, clear => clear, charRdy => charRdy, char => char, x => std_logic_vector(x), y => std_logic_vector(y), hSync => hSync, vSync => vSync, RGB => RGB );
  
  xCounter:
  process (rst_n, clk)
  begin
    if rst_n='0' then
      x <= (others => '0');
    elsif rising_edge(clk) then
      if clear='1' then
        x <= (others => '0');
      elsif newLine='1' then
        x <= (others => '0');
      elsif charRdy='1' then
        if x=COLSxLINE then
          x <= (others => '0');
        else
          x <= x + 1;
        end if;
      end if;
    end if;
  end process;
  
  yCounter:
  process (rst_n, clk)
  begin
    if rst_n='0' then
      y <= (others => '0');
    elsif rising_edge(clk) then
      if clear='1' then
        y <= (others => '0');
      elsif newLine='1' or (charRdy='1' and x=COLSxLINE) then
        if y=ROWSxFRAME then
          y <= (others => '0');
        else
          y <= y + 1;
        end if;
      end if;
    end if;
  end process;
  
end syn;

