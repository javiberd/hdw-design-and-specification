-------------------------------------------------------------------
--
--  Fichero:
--    ps2Receiver.vhd  15/7/2015
--
--    (c) J.M. Mendias
--    Diseo Automtico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Propsito:
--    Conversor elemental de una linea serie PS2 a paralelo con 
--    protocolo de strobe de 1 ciclo
--
--  Notas de diseo:
--
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ps2Receiver is
  generic (
    REGOUTPUTS : boolean   -- registra o no las salidas
  );
  port (
    -- host side
    rst_n      : in  std_logic;   -- reset asncrono del sistema (a baja)
    clk        : in  std_logic;   -- reloj del sistema
    dataRdy    : out std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato recibido
    data       : out std_logic_vector (7 downto 0);  -- dato recibido
    -- PS2 side
    ps2Clk     : in  std_logic;   -- entrada de reloj del interfaz PS2
    ps2Data    : in  std_logic    -- entrada de datos serie del interfaz PS2
  );
end ps2Receiver;

-------------------------------------------------------------------

use work.common.all;

architecture syn of ps2Receiver is
 
  signal ps2ClkSync, ps2DataSync, ps2ClkFall, ps2ClkSync_n: std_logic; 
  signal ps2DataShf: std_logic_vector(10 downto 0);
  signal lastBit, parityOK: std_logic;

begin

  ps2ClkSynchronizer : synchronizer 
    generic map ( STAGES => 2, INIT => '1' )
    port map ( rst_n => rst_n, clk => clk, x => ps2Clk, xSync => ps2ClkSync );  
  
  ps2ClkEdgeDetector : edgeDetector
    port map ( rst_n => rst_n, clk => clk, x_n => ps2ClkSync, xFall => ps2ClkFall , xRise => open ); 
    
  ps2DataSynchronizer : synchronizer
    generic map ( STAGES => 2, INIT => '1' )
    port map ( rst_n => rst_n, clk => clk, x => ps2Data, xSync => ps2DataSync );  

    
  ps2DataShifter:
  process (rst_n, clk)
  begin
    if rst_n='0' then
      ps2DataShf <= (others =>'1');    
    elsif rising_edge(clk) then
      if lastBit = '1' then
        ps2DataShf <= (others => '1');
      elsif ps2ClkFall = '1' then
        ps2DataShf <= ps2DataSync & ps2DataShf(10 downto 1);
      end if;
    end if;
  end process;

  oddParityCheker :
  parityOK <= ps2DataShf(9) xor ps2DataShf(8) xor ps2DataShf(7) xor ps2DataShf(6) xor ps2DataShf(5) 
                                xor ps2DataShf(4) xor ps2DataShf(3) xor ps2DataShf(2) xor ps2DataShf(1);

  lastBitCheker :
  lastBit <= not ps2DataShf(0);  
  
  outputRegisters:
  if REGOUTPUTS generate
    process (rst_n, clk)
    begin
      if rst_n='0' then
        dataRdy <= '0';
        data <= (others=>'0');
      elsif rising_edge(clk) then
        dataRdy <= parityOk and lastBit;
        if parityOk = '1' and lastBit = '1' then
          data <= ps2DataShf(8 downto 1);
        end if;
      end if;
    end process;
  end generate;
 
  outputSignals:
  if not REGOUTPUTS generate
    dataRdy <= parityOk and lastBit;
    data    <= ps2DataShf(8 downto 1);
  end generate;

end syn;
