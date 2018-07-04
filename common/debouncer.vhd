-------------------------------------------------------------------
--
--  Fichero:
--    debouncer.vhd  15/7/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Elimina los rebotes de una línea binaria mediante la espera 
--    tras cada flanco detectado
--
--  Notas de diseño:
--    - Asume que el la señal en reposo vale '1'
--
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity debouncer is
  generic(
    FREQ   : natural;  -- frecuencia de operacion en KHz
    BOUNCE : natural   -- tiempo de rebote en ms
  );
  port (
    rst_n  : in  std_logic;   -- reset asíncrono del sistema (a baja)
    clk    : in  std_logic;   -- reloj del sistema
    x_n    : in  std_logic;   -- entrada binaria a la que deben eliminarse los rebotes (a baja en reposo)
    xdeb_n : out std_logic    -- salida que sique a la entrada pero sin rebotes
  );
end debouncer;

-------------------------------------------------------------------

architecture syn of debouncer is

  signal startTimer, timerEnd: std_logic;
  
begin

  timer:
  process (rst_n, clk)
    constant TIMEOUT : natural := (BOUNCE*FREQ)-1;
    variable count   : natural range 0 to TIMEOUT;
  begin
    if count=0 then
      timerEnd <= '1';
    else 
      timerEnd <= '0';
    end if;
    if rst_n='0' then
      count := 0;
    elsif rising_edge(clk) then
      if startTimer='1' then
        count := TIMEOUT;
      elsif timerEnd='0' then
        count := count - 1;
      end if;
    end if;
  end process;
    
  fsm:
  process (rst_n, clk, x_n)
    type states is (waitingKeyDown, keyDownDebouncing, waitingKeyUp, KeyUpDebouncing); 
    variable state: states;
  begin 
    xDeb_n <= '1';
    startTimer <= '0';
    case state is
      when waitingKeyDown =>
        if x_n='0' then
          startTimer <= '1';
        end if;
      when keyDownDebouncing =>
        xDeb_n <= '0';
      when waitingKeyUp =>
        xDeb_n <= '0';
        if x_n='1' then
          startTimer <= '1';
        end if;
      when KeyUpDebouncing =>
        null;
    end case;
    if rst_n='0' then
      state := waitingKeyDown;
    elsif rising_edge(clk) then
      case state is
        when waitingKeyDown =>
          if x_n='0' then
            state := keyDownDebouncing;
          end if;
        when keyDownDebouncing =>
          if timerEnd='1' then
            state := waitingKeyUp;
          end if;
        when waitingKeyUp =>
          if x_n='1' then
            state := KeyUpDebouncing;
          end if;
        when KeyUpDebouncing =>
          if timerEnd='1' then
            state := waitingKeyDown;
          end if;
      end case;
    end if;
  end process;  

end syn;
