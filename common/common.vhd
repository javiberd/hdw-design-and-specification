---------------------------------------------------------------------
--
--  Fichero:
--    common.vhd  22/3/2017
--
--    (c) J.M. Mendias
--    Diseo Automtico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Propsito:
--    Contiene definiciones de constantes, funciones de utilidad
--    y componentes reusables
--
--  Notas de diseo:
--
---------------------------------------------------------------------

library IEEE;
use ieee.numeric_std.all;
use IEEE.std_logic_1164.all;

package common is

  constant YES  : std_logic := '1';
  constant NO   : std_logic := '0';
  constant HI   : std_logic := '1';
  constant LO   : std_logic := '0';
  constant ONE  : std_logic := '1';
  constant ZERO : std_logic := '0';
  
  -- Calcula el logaritmo en base-2 de un numero.
  function log2(v : in natural) return natural;
  -- Selecciona un entero entre dos.
  function int_select(s : in boolean; a : in integer; b : in integer) return integer;
  -- Convierte un real en un signed en punto fijo con qn bits enteros y qm bits decimales. 
  function toFix( d: real; qn : natural; qm : natural ) return signed; 
  
  -- Convierte codigo binario a codigo 7-segmentos
  component bin2segs
    port
    (
      -- host side
      bin  : in  std_logic_vector(3 downto 0);   -- codigo binario
      dp   : in  std_logic;                      -- punto
      -- leds side
      segs : out std_logic_vector(7 downto 0)    -- codigo 7-segmentos
    );
  end component;
  
  component synchronizer
  generic (
    STAGES  : in natural;      -- nmero de biestables del sincronizador
    INIT    : in std_logic     -- valor inicial de los biestables 
  );
  port (
    rst_n : in  std_logic;   -- reset asncrono de entrada (a baja)
    clk   : in  std_logic;   -- reloj del sistema
    x     : in  std_logic;   -- entrada binaria a sincronizar
    xSync : out std_logic    -- salida sincronizada que sique a la entrada
  );
  end component;
  
  component debouncer
  generic(
    FREQ   : natural;  -- frecuencia de operacion en KHz
    BOUNCE : natural   -- tiempo de rebote en ms
  );
  port (
    rst_n  : in  std_logic;   -- reset asncrono del sistema (a baja)
    clk    : in  std_logic;   -- reloj del sistema
    x_n    : in  std_logic;   -- entrada binaria a la que deben eliminarse los rebotes (a baja en reposo)
    xdeb_n : out std_logic    -- salida que sique a la entrada pero sin rebotes
  );
  end component;
  
  component edgeDetector
  port (
    rst_n : in  std_logic;   -- reset asncrono del sistema (a baja)
    clk   : in  std_logic;   -- reloj del sistema
    x_n   : in  std_logic;   -- entrada binaria con flancos a detectar (a baja en reposo)
    xFall : out std_logic;   -- se activa durante 1 ciclo cada vez que detecta un flanco de subida en x
    xRise : out std_logic    -- se activa durante 1 ciclo cada vez que detecta un flanco de bajada en x
  );
  end component;
  
  component frequencySynthesizer
  generic (
    FREQ     : natural;                 -- frecuencia del reloj de entrada en KHz
    MODE     : string;                  -- modo del sintetizador de frecuencia "LOW" o "HIGH"
    MULTIPLY : natural range 2 to 32;   -- factor por el que multiplicar la frecuencia de entrada 
    DIVIDE   : natural range 1 to 32    -- divisor por el que dividir la frecuencia de entrada
  );
  port (
    clkIn  : in  std_logic;   -- reloj de entrada
    ready  : out std_logic;   -- indica si el reloj de salida es vlido
    clkOut : out std_logic    -- reloj de salida
  );
  end component;
  
  component ps2Receiver
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
end component;

component rs232Receiver
  generic (
    FREQ     : natural;  -- frecuencia de operacion en KHz
    BAUDRATE : natural   -- velocidad de comunicacion
  );
  port (
    -- host side
    rst_n   : in  std_logic;   -- reset asncrono del sistema (a baja)
    clk     : in  std_logic;   -- reloj del sistema
    dataRdy : out std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato recibido
    data    : out std_logic_vector (7 downto 0);   -- dato recibido
    -- RS232 side
    RxD     : in  std_logic    -- entrada de datos serie del interfaz RS-232
  );
end component;

component rs232Transmitter
  generic (
    FREQ     : natural;  -- frecuencia de operacion en KHz
    BAUDRATE : natural   -- velocidad de comunicacion
  );
  port (
    -- host side
    rst_n   : in  std_logic;   -- reset asncrono del sistema (a baja)
    clk     : in  std_logic;   -- reloj del sistema
    dataRdy : in  std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato a transmitir
    data    : in  std_logic_vector (7 downto 0);   -- dato a transmitir
    busy    : out std_logic;   -- se activa mientras esta transmitiendo
    -- RS232 side
    TxD     : out std_logic    -- salida de datos serie del interfaz RS-232
  );
end component;

component fifo
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
end component;

component vgaInterface
  generic(
    FREQ      : natural;  -- frecuencia de operacion en KHz
    SYNCDELAY : natural   -- numero de pixeles a retrasar las seales de sincronismo respecto a las de posicin
  );
  port ( 
    -- host side
    rst_n : in  std_logic;   -- reset asncrono del sistema (a baja)
    clk   : in  std_logic;   -- reloj del sistema
    line  : out std_logic_vector(9 downto 0);   -- numero de linea que se esta barriendo
    pixel : out std_logic_vector(9 downto 0);   -- numero de pixel que se esta barriendo
    R     : in  std_logic_vector(2 downto 0);   -- intensidad roja del pixel que se esta barriendo
    G     : in  std_logic_vector(2 downto 0);   -- intensidad verde del pixel que se esta barriendo
    B     : in  std_logic_vector(2 downto 0);   -- intensidad azul del pixel que se esta barriendo
    -- VGA side
    hSync : out std_logic;   -- sincronizacion horizontal
    vSync : out std_logic;   -- sincronizacion vertical
    RGB   : out std_logic_vector(8 downto 0)   -- canales de color
  );
end component;

component vgaTxtInterface
  generic(
    FREQ   : natural  -- frecuencia de operacion en KHz
  );
  port ( 
    -- host side
    rst_n   : in std_logic;   -- reset asncrono del sistema (a baja)
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
end component;

component iisInterface
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
end component;

component desckewer
  generic (
    FREQ     : natural           -- frecuencia del reloj de entrada en KHz
  );
  port (
    clkIn    : in  std_logic;    -- oscilador externo
    ready    : out std_logic;    -- se activa cuando las seales de reloj son validas
    intClk   : out std_logic;    -- reloj interno con bajo skew
    extClk   : out std_logic;    -- reloj externo con bajo skew
    extClkFb : in  std_logic     -- seal de feedback del reloj externo (usado para compensar el skew del PCB)
  );
end component;

component sdramController
  generic(
    FREQ                 :     natural;  -- operating frequency in KHz
    PIPE_EN              :     boolean;  -- if true, enable pipelined read operations
    MAX_NOP              :     natural;  -- number of NOPs before entering self-refresh
    ENABLE_REFRESH       :     boolean;   -- if true, row refreshes are automatically inserted
    MULTIPLE_ACTIVE_ROWS :     boolean;  -- if true, allow an active row in each bank
    DATA_WIDTH           :     natural;  -- host & SDRAM data width
    NROWS                :     natural;  -- number of rows in SDRAM array
    NCOLS                :     natural;  -- number of columns in SDRAM array
    HADDR_WIDTH          :     natural;  -- host-side address width
    SADDR_WIDTH          :     natural  -- SDRAM-side address width
    );
  port(
    -- host side
    clk                  : in  std_logic;  -- master clock
    lock                 : in  std_logic;  -- true if clock is stable
    rst                  : in  std_logic;  -- reset
    rd                   : in  std_logic;  -- initiate read operation
    wr                   : in  std_logic;  -- initiate write operation
    earlyOpBegun         : out std_logic;  -- read/write/self-refresh op has begun (async)
    opBegun              : out std_logic;  -- read/write/self-refresh op has begun (clocked)
    rdPending            : out std_logic;  -- true if read operation(s) are still in the pipeline
    done                 : out std_logic;  -- read or write operation is done
    rdDone               : out std_logic;  -- read operation is done and data is available
    hAddr                : in  std_logic_vector(HADDR_WIDTH-1 downto 0);  -- address from host to SDRAM
    hDIn                 : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- data from host       to SDRAM
    hDOut                : out std_logic_vector(DATA_WIDTH-1 downto 0);  -- data from SDRAM to host
    -- SDRAM side
    cke     : out std_logic;            -- clock-enable to SDRAM
    ce_n    : out std_logic;            -- chip-select to SDRAM
    ras_n   : out std_logic;            -- SDRAM row address strobe
    cas_n   : out std_logic;            -- SDRAM column address strobe
    we_n    : out std_logic;            -- SDRAM write enable
    ba      : out std_logic_vector(1 downto 0);  -- SDRAM bank address
    sAddr   : out std_logic_vector(SADDR_WIDTH-1 downto 0);  -- SDRAM row/column address
    sData   : inout std_logic_vector(DATA_WIDTH-1 downto 0); -- data from/to SRAM
    dqmh    : out std_logic;            -- enable upper-byte of SDRAM databus if true
    dqml    : out std_logic             -- enable lower-byte of SDRAM databus if true
    );
end component;

component busWrapper
  generic 
  (
    NUMREG    : natural;   -- numero de registros del dispositivo a conectar al bus
    DWIDTH    : natural;   -- anchura del bus de datos
    AWIDTH    : natural;   -- anchura del bus de direcciones
    BASEADDR  : natural    -- direccion inicial de los registros del dispositivo
  );
  port  
  (
    -- bus side
    wrCE    : in    std_logic;   -- habilitacin de escritura
    rdCE    : in    std_logic;   -- habilitacin de lectura
    aBus    : in    std_logic_vector(AWIDTH-1 downto 0);   -- direccion
    dBus    : inout std_logic_vector(DWIDTH-1 downto 0);   -- datos
    -- device side
    regSel  : out   std_logic_vector(log2(NUMREG)-1 downto 0);   -- selecciona un registro del dispositivo
    wrE     : out   std_logic;   -- se activa durante 1 ciclo para escribir un registro del dispositivo
    dataIn  : out   std_logic_vector(DWIDTH-1 downto 0);   -- dato a escribir 
    rdE     : out   std_logic;   -- se activa durante 1 ciclo para leer un registro del dispositivo
    dataOut : in    std_logic_vector(DWIDTH-1 downto 0)    -- dato a leer
  );
end component;

component kcpsm3
    Port (      address : out std_logic_vector(9 downto 0);
            instruction : in std_logic_vector(17 downto 0);
                port_id : out std_logic_vector(7 downto 0);
           write_strobe : out std_logic;
               out_port : out std_logic_vector(7 downto 0);
            read_strobe : out std_logic;
                in_port : in std_logic_vector(7 downto 0);
              interrupt : in std_logic;
          interrupt_ack : out std_logic;
                  reset : in std_logic;
                    clk : in std_logic);
end component;

component gpio
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
end component;

end package common;

-------------------------------------------------------------------

package body common is

  function log2(v : in natural) return natural is
    variable n    : natural;
    variable logn : natural;
  begin
    n := 1;
    for i in 0 to 128 loop
      logn := i;
      exit when (n >= v);
      n := n * 2;
    end loop;
    return logn;
  end function log2;
  
  function int_select(s : in boolean; a : in integer; b : in integer) return integer is
  begin
    if s then
      return a;
    else
      return b;
    end if;
    return a;
  end function int_select;
  
  function toFix( d: real; qn : natural; qm : natural ) return signed is 
  begin 
    return to_signed( integer(d*(2.0**qm)), qn+qm );
  end function; 
  
end package body common;
