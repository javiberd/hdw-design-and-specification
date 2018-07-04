---------------------------------------------------------------------
--
--  Fichero:
--    monocycleNotchFilter.vhd  22/3/2017
--
--    (c) J.M. Mendias
--    Diseo Automtico de Sistemas
--    Facultad de Informtica. Universidad Complutense de Madrid
--
--  Propsito:
--    Filtro IIR de segundo orden tipo notch de caracteristicas 
--    configurables e implementacin monociclo
--
--  Notas de diseo:
--    - Los coeficientes se calculan segun las especificaciones de
--      S.J. Orfanidis, "Introduction to Signal Processing" 
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity monocycleNotchFilter is
  generic (
    WL : natural;  -- anchura de la muestra
    QM : natural;  -- nmero de bits decimales en la muestra
    FS : real;     -- frecuencia de muestreo
    F0 : real      -- frecuencia de corte
  );
  port(
    rst_n     : in    std_logic;  -- reset asncrono del sistema (a baja)
    clk       : in    std_logic;  -- reloj del sistema
    newSample : in    std_logic;  -- indica si existe una nueva muestra que procesar
    inSample  : in    std_logic_vector(WL-1 downto 0);  -- muestra de entrada
    outSample : out   std_logic_vector(WL-1 downto 0)   -- muestra de salida
  );
end monocycleNotchFilter;

-------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.common.all;

architecture syn of monocycleNotchFilter is

  constant QN : natural := WL-QM;  -- nmero de bits enteros en la muestra

  type signedArray is array (0 to 2) of signed(WL-1 downto 0);
  
  constant QF : real := 60.0;                            -- factor de calidad
  constant w0 : real := 2.0*MATH_PI*F0/FS;               -- frecuencia de corte en radianes/muestra
  constant k  : real := 1.0 / (1.0 + tan(w0/(2.0*QF)));  -- factor de escala 
   
  constant a : signedArray := ( 
    toFix( k, QN, QM ), 
    toFix( -2.0*k*cos(w0), QN, QM ), 
    toFix( k, QN, QM ) 
  ); 
  constant b : signedArray := ( 
    toFix( 0.0, QN, QM ),
    toFix( 2.0*k*cos(w0), QN, QM ),
    toFix( -(2.0*k - 1.0), QN, QM )
  );
 
  signal x, y : signedArray;
  signal acc  : signed(2*WL-1 downto 0);

begin
 
  outSample <= std_logic_vector(y(0));

  filterFU :
  acc <= ((((a(0) * x(0)) + (a(1) * x(1))) + (a(2) * x(2))) + (b(1) * y(1))) + (b(2) * y(2));

  wrapping :
  y(0) <= acc((QN + 2 * QM - 1) downto QM);

  filterRegisters :
  process (rst_n, clk)
  begin
    if rst_n='0' then
      x(0) <= (others => '0');
      x(1) <= (others => '0');
      x(2) <= (others => '0');
      y(1) <= (others => '0');
      y(2) <= (others => '0');
    elsif rising_edge(clk) then
      if newSample='1' then
        x(0) <= signed(inSample);
        x(1) <= x(0);
        x(2) <= x(1);
        y(1) <= y(0);
        y(2) <= y(1);
      end if;
    end if; 
  end process;
   
end syn;

