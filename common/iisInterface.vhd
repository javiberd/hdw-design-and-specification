---------------------------------------------------------------------
--
--  Fichero:
--    issInterface.vhd  29/7/2015
--
--    (c) J.M. Mendias
--    Diseo Automtico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Propsito:
--    Transmite/recibe muestras de sonido por un bus IIS con
--    20 bits, fs=48.8 KHz, fsclk = 64fs y fmclk=256fs
--
--  Notas de diseo:
--    - Solo vlido para 50 MHz de frecuencia de reloj
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity iisInterface is
  generic (
    WIDTH : natural   -- anchura de las muestras
  );
  port ( 
    -- host side
    rst_n        : in  std_logic;   -- reset asncrono del sistema (a baja)
    clk          : in  std_logic;   -- reloj del sistema
    leftChannel  : out std_logic;   -- en alta cuando la muestra corresponde al canal izquiero; a baja cuando es el derecho
    outSample    : in std_logic_vector(WIDTH-1 downto 0);   -- muestra a enviar al AudioCodec
    outSampleRqt : out std_logic;                           -- se activa durante 1 ciclo cada vez que se requiere un nuevo dato a enviar
    inSample     : out std_logic_vector(WIDTH-1 downto 0);  -- muestra recibida del AudioCodec
    inSampleRdy  : out std_logic;                           -- se activa durante 1 ciclo cada vez que hay un nuevo dato recibido
    -- IIS side
    mclk : out std_logic;   -- master clock, 256fs
    sclk : out std_logic;   -- serial bit clocl, 64fs
    lrck : out std_logic;   -- left-right clock, fs
    sdti : out std_logic;   -- datos serie hacia DACs
    sdto : in  std_logic    -- datos serie desde ADCs
  );
end iisInterface;

---------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;

architecture syn of iisInterface is

  signal clkGen   : unsigned(9 downto 0); 
  signal clkCycle : unsigned(3 downto 0);
  signal bitNum   : unsigned(4 downto 0);

begin

  clkGenCounter: 
  process (rst_n, clk)
  begin
    if rst_n='0' then
      clkGen <= (others => '0');
    elsif rising_edge(clk) then
      if clkGen=1023 then
        clkGen <= (others => '0');
      else
        clkGen <= clkGen + 1;
      end if;
    end if;
  end process;
                                                                                                            
  mclk <= clkGen(1);
  sclk <= clkGen(3);
  lrck <= clkGen(9);
  
  clkCycle <= clkGen(3 downto 0);
  bitNum <= clkGen(8 downto 4);

  leftChannel <= clkGen(9);
  
  -------------  

  outSampleRqt <= '1' when bitNum=11 and clkCycle=15 else '0';

  outSampleShifter: 
  process (rst_n, clk)
    variable sample: std_logic_vector(19 downto 0);
  begin
    sdti <= sample(19);
    if rst_n='0' then
      sample := (others => '0');
    elsif rising_edge(clk) then
      if bitNum=11 and clkCycle=15 then
        if outSample(WIDTH - 1)='1' then
          sample := (19 downto outSample'length => '1') & outSample;
        else
          sample := (19 downto outSample'length => '0') & outSample;
        end if;
      elsif bitNum>11 and clkCycle=15 then
        sample(19 downto 1) := sample(18 downto 0);
      end if;
    end if;
  end process;
  
  -------------
  
  inSampleRdy <= '1' when bitNum=20 and clkCycle=0 else '0'; 

  inSampleShifter:
  process (rst_n, clk)
    variable sample: std_logic_vector (19 downto 0);
  begin
    inSample <= sample(19 downto 4);
    if rst_n='0' then
      sample := (others => '0');
    elsif rising_edge(clk) then
      if bitNum < 20 and clkCycle=7 then
        sample(19 downto 1) := sample(18 downto 0);
		  sample(0) := sdto;
      end if;
    end if;
  end process;
  
end syn;
