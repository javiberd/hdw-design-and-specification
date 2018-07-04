---------------------------------------------------------------------
--
--  Fichero:
--    vgaTxtInterface.vhd  4/11/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Genera las señales de color y sincronismo de un interfaz texto
--    VGA con resolución de 80x30 caracteres de 8x16 pixeles.
--
--  Notas de diseño:
--    - Para frecuencias a partir de 50 Mhz en multiplos de 25 MHz
--    - Incluye una memoria de refresco para almacenar los caracteres
--      a visualizar y una memoria de mapas de bits de cada caracter 
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity vgaTxtInterface is
  generic(
    FREQ   : natural  -- frecuencia de operacion en KHz
  );
  port ( 
    -- host side
    rst_n   : in std_logic;   -- reset asíncrono del sistema (a baja)
    clk     : in std_logic;   -- reloj del sistema
    clear   : in std_logic;   -- borra la memoria de refresco
    charRdy : in std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo caracter a visualizar
    char    : in std_logic_vector (7 downto 0);   -- codigo ASCII del caracter a visualizar
    x       : in std_logic_vector (6 downto 0);   -- columna en donde visualizar el caracter
    y       : in std_logic_vector (4 downto 0);   -- fila en donde visualizar el caracter
    -- VGA side
    hSync : out std_logic;   -- sincronizacion horizontal
    vSync : out std_logic;   -- sincronizacion vertical
    RGB   : out std_logic_vector (8 downto 0)   -- canales de color
  );
end vgaTxtInterface;

---------------------------------------------------------------------

library ieee, unisim;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use work.common.all;

architecture syn of vgaTxtInterface is

  constant COLSxLINE  : natural := 80;
  constant ROWSxFRAME : natural := 30;

  signal pixel : std_logic_vector (9 downto 0);
  signal line  : std_logic_vector (9 downto 0);

  signal col, clearCol : unsigned (x'range);
  signal row, clearRow : unsigned (y'range);
  signal uCol : unsigned (2 downto 0);
  signal uRow : unsigned (3 downto 0);
  
  signal clearingRam : std_logic;
   
  signal asciiCode, ramDataLow, ramDataHigh, romDataLow, romDataHigh, bitMapLine : std_logic_vector(7 downto 0);
  
  signal romAddr : std_logic_vector (11 downto 0);
  signal ramAddrA, ramAddrB : std_logic_vector (11 downto 0);

  signal weA : std_logic;
  signal dataA : std_logic_vector (7 downto 0);
  
  signal color : std_logic_vector (2 downto 0);
 
  function bitReverse(x : in bit_vector(0 to 255)) return bit_vector is
    variable result : bit_vector(255 downto 0);
  begin
    for i in 255 downto 0 loop
      result(i) := x(i);
    end loop;
    return result;
  end function bitReverse;
  
begin
  
  clearCounters:
  process (rst_n, clk, clearCol, clearRow)
  begin
	if rst_n='0' then
    clearingRam <= '0';
		clearCol <= (others => '0');
		clearRow <= (others => '0');
	elsif rising_edge(clk) then
    if clear='1' then
      clearingRam <= '1';
      clearCol <= (others => '0');
      clearRow <= (others => '0');
    elsif clearingRam='1' then
      if clearCol=COLSxLINE then
        clearCol <= (others => '0');
      else
        clearCol <= clearCol + 1;
      end if;
      if clearRow=ROWSxFRAME then
        clearRow <= (others => '0');
      else
        clearRow <= clearRow + 1;
      end if;
      if clearCol=COLSxLINE and clearRow=ROWSxFRAME then
        clearingRam <= '0';
      end if;
    end if;
  end if;
  end process;
  
------------------
  
  screenInteface: vgaInterface
    generic map ( FREQ => 50_000, SYNCDELAY => 2 )
    port map ( rst_n => rst_n, clk => clk, line => line, pixel => pixel, R => color, G => color, B => color, hSync => hSync, vSync => vSync, RGB => RGB );

  col <= unsigned(pixel(9 downto 3));
  uCol <= unsigned(pixel(2 downto 0));
  
  row <= unsigned(line(8 downto 4));
  uRow <= unsigned(line(3 downto 0));
  
  color <= "111" when bitMapLine(to_integer(ucol-1))='1' else "000";  
    
------------------  

  charRamLow : RAMB16_S9_S9  
    port map ( doA => open,       dopA => open, addrA => ramAddrA(10 downto 0), clkA => clk, diA => dataA,           dipA => (others => '0'), enA => not ramAddrA(11), ssrA => '0', weA => weA,
               doB => ramDataLow, dopB => open, addrB => ramAddrB(10 downto 0), clkB => clk, diB => (others => '0'), dipB => (others => '0'), enB => '1', ssrB => '0', weB => '0');
  
  charRamHigh : RAMB16_S9_S9  
    port map ( doA => open,       dopA => open, addrA => ramAddrA(10 downto 0), clkA => clk, diA => dataA,           dipA => (others => '0'), enA => ramAddrA(11), ssrA => '0', weA => weA,
               doB => ramDataHigh, dopB => open, addrB => ramAddrB(10 downto 0), clkB => clk, diB => (others => '0'), dipB => (others => '0'), enB => '1', ssrB => '0', weB => '0');
    
  weA      <= '1' when charRdy='1' or clearingRam='1' else '0';
  dataA    <= char when clearingRam='0' else (others => '0');      
  ramAddrA <= std_logic_vector(x & y) when clearingRam='0' else std_logic_vector(clearCol & clearRow); 
  ramAddrB <= std_logic_vector(col & row);

  asciiCode <= ramDataHigh when ramAddrB(11)='1' else ramDataLow;
  
------------------  
  
  bitMapRomLow: RAMB16_S9  
    generic map (
      INIT_00 => bitReverse(X"00000000000000000000000000000000_007e4242424242424242424242427e00"), -- null empty
      INIT_01 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_02 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_03 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_04 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_05 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_06 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_07 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_08 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_09 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_0A => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_0B => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_0C => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_0D => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_0E => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_0F => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_10 => bitReverse(X"00000000000000000000000000000000_000000183c3c3c181800181800000000"), -- space ! 
      INIT_11 => bitReverse(X"0000c6c6c64400000000000000000000_0000006c6cfe6c6c6cfe6c6c00000000"), -- " #
      INIT_12 => bitReverse(X"0018187cc6c2c07c0686c67c18180000_0000000000c3c60c183063c300000000"), -- $ %
      INIT_13 => bitReverse(X"000000386c6c3876dccccc7600000000_00003030306000000000000000000000"), -- & ´
      INIT_14 => bitReverse(X"00000018306060606060301800000000_000000180c06060606060c1800000000"), -- ( )
      INIT_15 => bitReverse(X"00000000006c38fe386c000000000000_000000001818187e1818180000000000"), -- * +  
      INIT_16 => bitReverse(X"00000000000000000018181830000000_00000000000000fe0000000000000000"), --   -
      INIT_17 => bitReverse(X"00000000000000000000181800000000_00000002060c183060c0800000000000"), -- . /
      INIT_18 => bitReverse(X"0000007cc6cedef6e6c6c67c00000000_00000018387818181818187e00000000"), -- 0 1
      INIT_19 => bitReverse(X"0000007cc6060c183060c6fe00000000_0000007cc606063c0606c67c00000000"), -- 2 3
      INIT_1A => bitReverse(X"0000000c1c3c6cccfe0c0c1e00000000_000000fec0c0c0fc0606c67c00000000"), -- 4 5
      INIT_1B => bitReverse(X"0000003860c0c0fcc6c6c67c00000000_000000fec6060c183030303000000000"), -- 6 7
      INIT_1C => bitReverse(X"0000007cc6c6c67cc6c6c67c00000000_0000007cc6c6c67e06060c7800000000"), -- 8 9
      INIT_1D => bitReverse(X"00000000181800000018180000000000_00000000181800000018183000000000"), -- : ;
      INIT_1E => bitReverse(X"000000060c18306030180c0600000000_0000000000007e00007e000000000000"), -- < =
      INIT_1F => bitReverse(X"0000006030180c060c18306000000000_0000007cc6c60c181800181800000000"), -- > ?  
      INIT_20 => bitReverse(X"0000007cc6c6dedededcc07c00000000_00000010386cc6c6fec6c6c600000000"), -- @ A
      INIT_21 => bitReverse(X"000000fc6666667c666666fc00000000_0000003c66c2c0c0c0c2663c00000000"), -- B C
      INIT_22 => bitReverse(X"000000f86c66666666666cf800000000_000000fe66626878686266fe00000000"), -- D E
      INIT_23 => bitReverse(X"000000fe66626878686060f000000000_0000003c66c2c0c0dec6663a00000000"), -- F G
      INIT_24 => bitReverse(X"000000c6c6c6c6fec6c6c6c600000000_0000003c181818181818183c00000000"), -- H I
      INIT_25 => bitReverse(X"0000001e0c0c0c0c0ccccc7800000000_000000e6666c6c786c6c66e600000000"), -- J K
      INIT_26 => bitReverse(X"000000f060606060606266fe00000000_000000c6eefed6c6c6c6c6c600000000"), -- L M
      INIT_27 => bitReverse(X"000000c6e6f6fedecec6c6c600000000_000000386cc6c6c6c6c66c3800000000"), -- N O
      INIT_28 => bitReverse(X"000000fc6666667c606060f000000000_0000007cc6c6c6d6de7c0c0e00000000"), -- P Q
      INIT_29 => bitReverse(X"000000fc6666667c6c6666e600000000_0000007cc6c660380cc6c67c00000000"), -- R S
      INIT_2A => bitReverse(X"0000007e5a1818181818183c00000000_000000c6c6c6c6c6c6c6c67c00000000"), -- T U
      INIT_2B => bitReverse(X"000000c6c6c6c6c6c66c381000000000_000000c6c6c6c6c6d6feeec600000000"), -- V W
      INIT_2C => bitReverse(X"000000c6c6c66c386cc6c6c600000000_000000c6c6c66c383838387c00000000"), -- X Y
      INIT_2D => bitReverse(X"000000fec68c183060c2c6fe00000000_0000003c303030303030303c00000000"), -- Z [
      INIT_2E => bitReverse(X"00000080c0e070381c0e060200000000_0000003c0c0c0c0c0c0c0c3c00000000"), -- \ ]
      INIT_2F => bitReverse(X"0010386cc60000000000000000000000_00000000000000000000000000fe0000"), -- ^ _   
      INIT_30 => bitReverse(X"00003030180000000000000000000000_000000000000780c7ccccc7600000000"), -- ` a
      INIT_31 => bitReverse(X"000000e06060786c666666dc00000000_0000000000007cc6c0c0c67c00000000"), -- b c
      INIT_32 => bitReverse(X"0000001c0c0c3c6ccccccc7600000000_0000000000007cc6fec0c67c00000000"), -- d e
      INIT_33 => bitReverse(X"0000001c3632307c3030307800000000_00000000000076cccccc7c0ccc780000"), -- f g
      INIT_34 => bitReverse(X"000000e060606c76666666e600000000_00000018180038181818183c00000000"), -- h i
      INIT_35 => bitReverse(X"0000000606000e0606060666663c0000_000000e06060666c786c66e600000000"), -- j k
      INIT_36 => bitReverse(X"00000038181818181818183c00000000_00000000000044fed6d6d6d600000000"), -- l m
      INIT_37 => bitReverse(X"000000000000dc666666666600000000_0000000000007cc6c6c6c67c00000000"), -- n o
      INIT_38 => bitReverse(X"000000000000dc6666667c6060f00000_00000000000076cccccc7c0c0c1e0000"), -- p q
      INIT_39 => bitReverse(X"000000000000dc76666060f000000000_0000000000007cc6701cc67c00000000"), -- r s
      INIT_3A => bitReverse(X"000000103030fc303030361c00000000_000000000000cccccccccc7600000000"), -- t u
      INIT_3B => bitReverse(X"000000000000c6c6c66c381000000000_000000000000c6c6c6d6fe6c00000000"), -- v w
      INIT_3C => bitReverse(X"000000000000c66c38386cc600000000_000000000000c6c6c6c67e060c780000"), -- x y
      INIT_3D => bitReverse(X"000000000000fecc183066fe00000000_0000000e181818701818180e00000000"), -- z {
      INIT_3E => bitReverse(X"00000018181818001818181800000000_000000701818180e1818187000000000"), -- | }
      INIT_3F => bitReverse(X"00000076dc0000000000000000000000_007e4242424242424242424242427e00")  -- ~ empty
    )
    port map ( do => romDataLow, dop => open, addr => romAddr(10 downto 0), clk => clk, di => (others => '0'), dip => (others => '0'), en => '1', ssr => '0', we => '0');

  bitMapRomHigh: RAMB16_S9  
    generic map (
      INIT_00 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_01 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_02 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_03 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_04 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_05 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_06 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_07 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_08 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_09 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_0A => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_0B => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_0C => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_0D => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_0E => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty
      INIT_0F => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_10 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty  
      INIT_11 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_12 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_13 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_14 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_15 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_16 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_17 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_18 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_19 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_1A => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_1B => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_1C => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_1D => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_1E => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_1F => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty  
      INIT_20 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_21 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_22 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_23 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_24 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_25 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_26 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_27 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_28 => bitReverse(X"007e4242424242424242424242427e00_000076dc0000dc666666666600000000"), -- empty Ñ 
      INIT_29 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_2A => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_2B => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_2C => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_2D => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_2E => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_2F => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty  
      INIT_30 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_31 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_32 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_33 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_34 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_35 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_36 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_37 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_38 => bitReverse(X"007e4242424242424242424242427e00_000076dc0000dc666666666600000000"), -- empty ñ 
      INIT_39 => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_3A => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_3B => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_3C => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_3D => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_3E => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00"), -- empty empty 
      INIT_3F => bitReverse(X"007e4242424242424242424242427e00_007e4242424242424242424242427e00")  -- empty empty 
	  )
	  port map ( do => romDataHigh, dop => open, addr => romAddr(10 downto 0), clk => clk, di => (others => '0'), dip => (others => '0'), en => '1', ssr => '0', we => '0');
    
  
    romAddr    <= asciiCode & std_logic_vector(uRow);
    bitMapLine <= romDataHigh when romAddr(11)='1' else romDataLow;

end syn;

