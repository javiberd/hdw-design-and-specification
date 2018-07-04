---------------------------------------------------------------------
--
--  Fichero:
--    gpio.vhd  30/9/2015
--
--    (c) J.M. Mendias
--    Diseo Automtico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Propsito:
--    Puerto de entrada/salida de propsito general programable
--    con protocolo de strobe de 1 ciclo de duracion
--
--  Notas de diseo:
--    - Desde el punto de vista del programador dispone de un
--      regitro de datos (tipo R/W) y un registro de configuracin
--      (tipo R/W).
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity gpio is
  generic
  (
    DWIDTH : natural;  -- anchura del bus de datos
    PWIDTH : natural   -- anchura del puerto
  );
  port  
  (
    -- host side
    rst_n   : in    std_logic;   -- reset asncrono del sistema (a baja)
    clk     : in    std_logic;   -- reloj del sistema
    regSel  : in    std_logic;   -- selecciona registro de datos/configuracin (0/1)
    wrE     : in    std_logic;   -- se activa durante 1 ciclo para escribir en el registro de datos/configuracin del puerto
    dataIn  : in    std_logic_vector(DWIDTH-1 downto 0);   -- dato a escribir
    rdE     : in    std_logic;   -- se activa durante 1 ciclo para leer el registro de datos/configuracin del puerto
    dataOut : out   std_logic_vector(DWIDTH-1 downto 0);   -- dato a leer
    int     : out   std_logic;   -- se actica durante 1 ciclo si alguna linea configurada como entrada cambia de valor
    -- io pads side
    io      : inout std_logic_vector(PWIDTH-1 downto 0)    -- entrada/salida del puerto (conexin a pines)
  );
end gpio;

---------------------------------------------------------------------

use work.common.all;

architecture syn of gpio is

  -- Codificacin de registros
  constant PDAT : std_logic := '0';
  constant PCON : std_logic := '1';
  
  -- Codificacin de PCON(i)
  constant OUTPUT  : std_logic := '0';
  constant INPUT   : std_logic := '1';
  
  signal ioSync : std_logic_vector(io'range);
  signal datReg : std_logic_vector(io'range);
  signal conReg : std_logic_vector(io'range);
    
begin
    
  configurationRegister :
  process (rst_n, clk)
  begin
    if rst_n='0' then
      conReg <= (others => '0');
    elsif rising_edge(clk) then
      if wrE='1' and regSel='1' then
        conReg <= dataIn;
      end if;
    end if;
  end process;

  dataRegister :
  process (rst_n, clk)
  begin
    if rst_n='0' then
      datReg <= (others => '0');
    elsif rising_edge(clk) then
      for i in io'range loop
        if (wrE='1' and regSel='0' and conReg(i)='0') or conReg(i)='1' then
          if conReg(i)='0' then
            datReg(i) <= dataIn(i);
          else
            datReg(i) <= ioSync(i);
          end if;
        end if;
      end loop;
    end if;
  end process;

  intGenerator:
  process( datReg, ioSync, conReg, ioSync )
    variable intAux : std_logic;
  begin
    int <= intAux;
    intAux := '0';
    for i in io'range loop
      intAux := (intAux or (conReg(i) and (datReg(i) xor ioSync(i))));
    end loop;
  end process;

  inputSynchronizer :
  for j in io'range generate
  begin
    sync : synchronizer
    generic map ( STAGES => 1, INIT => '0' )
    port map ( rst_n => rst_n, clk => clk, x => io(j), xSync => ioSync(j) );
  end generate;
  
--  ioBuffers :
--  for i in io'range generate
--    begin
--    if conReg(i)=INPUT then
--      io(i) <= datReg(i);
--    else
--      io(i) <= 'Z';
--    end if;
--  end generate;
  
  ioBuffers :
  process (conReg, datReg, io)
  begin
    for i in io'range loop
      if conReg(i)='0' then
        io(i) <= datReg(i);
      else
        io(i) <= 'Z';
      end if;
    end loop;
  end process;
  
  dataOutMux :
  process (regSel, rdE, conReg, datReg)
  begin
    for i in io'range loop
      if rdE='1' then
        if regSel='0' then
          dataOut(i) <= datReg(i);
        else
          dataOut(i) <= conReg(i);
        end if;
      else
        dataOut(i) <= 'Z';
      end if;
    end loop;
  end process;
  
end syn;
