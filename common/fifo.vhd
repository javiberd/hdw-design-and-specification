-------------------------------------------------------------------
--
--  Fichero:
--    fifo.vhd  1/10/2015
--
--    (c) J.M. Mendias
--    Diseo Automtico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Propsito:
--    Buffer de tipo FIFO
--
--  Notas de diseo:
--    - Est implementada como un banco de registros
--    - Si la FIFO est llena, los nuevos datos que se intenten 
--      almacenar se ignoran
--    - Si la FIFO est vaca, las lecturas devuelven valores no
--      validos
--
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity fifo is
  generic (
    WIDTH : natural;   -- anchura de la palabra de fifo
    DEPTH : natural    -- numero de palabras en fifo
  );
  port (
    rst_n   : in  std_logic;   -- reset asncrono del sistema (a baja)
    clk     : in  std_logic;   -- reloj del sistema
    wrE     : in  std_logic;   -- se activa durante 1 ciclo para escribir un dato en la fifo
    dataIn  : in  std_logic_vector(WIDTH-1 downto 0);   -- dato a escribir
    rdE     : in  std_logic;   -- se activa durante 1 ciclo para leer un dato de la fifo
    dataOut : out std_logic_vector(WIDTH-1 downto 0);   -- dato a leer
    full    : out std_logic;   -- indicador de fifo llena
    empty   : out std_logic    -- indicador de fifo vacia
  );
end fifo;

-------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of fifo is

  constant maxValue : natural := DEPTH-1;

  type   regFileType is array (0 to maxValue) of std_logic_vector(WIDTH-1 downto 0);

  -- Registros
  signal regFile : regFileType;
  signal wrPointer, rdPointer : natural range 0 to maxValue;
  signal isFull : std_logic;
  signal isEmpty : std_logic;
  -- Seales  
  signal nextWrPointer, nextRdPointer : natural range 0 to maxValue;
  signal rdFifo  : std_logic;
  signal wrFifo : std_logic;
  
begin

  registerFile :
  process (rst_n, clk, rdPointer, regFile)
  begin
    dataOut <= regFile(rdPointer);
    if rst_n='0' then
      regFile <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if wrFifo = '1' then 
        regFile(wrPointer) <= dataIn;
      end if;
    end if;
  end process;
 
  wrFifo <= wrE and (not isFull);
  rdFifo <= rdE and (not isEmpty);
  
  nextWrPointer <= wrPointer + 1;
  nextRdPointer <= rdPointer + 1;
  
  fsmd :
  process (rst_n, clk) 
  begin     
    if rst_n='0' then
      wrPointer <= 0;
      rdPointer <= 0;
      isFull    <= '0';
      isEmpty   <= '1';
    elsif rising_edge(clk) then
      if wrFifo='1' then
        wrPointer <= nextWrPointer;
        isEmpty <= '0';
        if nextWrPointer=rdPointer then
          isFull <= '1';
        end if;
      end if;
      if rdFifo='1' then
        rdPointer <= nextRdPointer;
        isFull <=  '0'; 
        if nextRdPointer=wrPointer then
          isEmpty <= '1';
        end if;
      end if;
    end if;
  end process;
 
  full <= isFull;
  empty <= isEmpty;
  
end syn;


