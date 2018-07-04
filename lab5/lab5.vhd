---------------------------------------------------------------------
--
--  Fichero:
--    lab5.vhd  15/7/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Laboratorio 5
--
--  Notas de diseño:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab5 is
  port (
    rstPb_n :  in std_logic;
    osc     :  in std_logic;
    RxD     :  in std_logic; 
    TxD     : out std_logic;
    TxEnable_n : in  std_logic;
    upSegs     : out std_logic_vector(7 downto 0);
    leftSegs   : out std_logic_vector(7 downto 0);
    rightSegs  : out std_logic_vector(7 downto 0)
  );
END lab5;

-----------------------------------------------------------------

use work.common.all;

architecture syn of lab5 is

  signal clk, rst_n : std_logic;

  signal dataRx, dataTx: std_logic_vector (7 downto 0);
  signal dataRdyTx, dataRdyRx, busy, empty, full: std_logic;
  
  signal TxEnableSync_n : std_logic;
  signal fifostatus : std_logic_vector (3 downto 0);
  
begin


  clk <= osc;
  
  resetSyncronizer : synchronizer
    generic map ( STAGES => 2, INIT => '0' )
    port map ( rst_n => rstPb_n, clk => clk, x => '1', xSync => rst_n );

  ------------------ 

  TxEnableSynchronizer : synchronizer
    generic map ( STAGES => 2, INIT => '1' )
    port map ( rst_n => rst_n, clk => clk, x => TxEnable_n, xSync => TxEnableSync_n );

  receiver: rs232receiver
    generic map ( FREQ => 50_000, BAUDRATE => 1200 )
    port map ( rst_n => rst_n, clk => clk, dataRdy => dataRdyRx, data => dataRx, RxD => RxD );

  fifo : fifo
    generic map ( WIDTH => 8, DEPTH => 16 )
    port map ( rst_n => rst_n, clk => clk, wrE => dataRdyRx, dataIn => dataRx, rdE => dataRdyTx, dataOut => dataTx, full => full, empty => empty );

  dataRdyTx <= not busy and not empty and not TxEnableSync_n;
   
  transmitter: rs232transmitter 
    generic map ( FREQ => 50_000, BAUDRATE => 1200 )
    port map ( rst_n => rst_n, clk => clk, dataRdy => dataRdyTx, data => dataTx, busy => busy, TxD => TxD );

  fifoStatus <= X"F" when full='1' else X"E" when empty='1' else X"0";
    
  upConverter : bin2segs 
    port map( bin => fifoStatus, dp => '0', segs => upSegs );
    
  leftConverter : bin2segs 
    port map( bin => dataRx(7 downto 4), dp => '0', segs => leftSegs );
  
  rigthConverter : bin2segs 
    port map( bin => dataRx(3 downto 0), dp => '0', segs => rightSegs ); 
    
end syn;