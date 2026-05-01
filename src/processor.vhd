LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY l6p1sim IS
    PORT( DIN : IN std_logic_vector(8 DOWNTO 0);
          Resetn, Clock, Run : IN std_logic;
          Done : BUFFER std_logic;
          BusWires : BUFFER std_logic_vector(8 DOWNTO 0));
END l6p1sim;

ARCHITECTURE Mixed OF l6p1sim IS
-- declare components
    COMPONENT dec3to8 IS
    PORT( W : IN std_logic_vector(2 DOWNTO 0);
          En : IN std_logic;
          Y : OUT std_logic_vector(0 TO 7));
    END COMPONENT;
    COMPONENT regn IS
    GENERIC( n : INTEGER := 9);
    PORT( R : IN std_logic_vector(n-1 DOWNTO 0);
          Rin, Clock : IN std_logic;
          Q : BUFFER std_logic_vector(n-1 DOWNTO 0));
    END COMPONENT;

-- declare signals
    TYPE State_type IS (T0, T1, T2, T3);
    SIGNAL Tstep_Q, Tstep_D: State_type;
    SIGNAL R0, R1, R2, R3, R4, R5, R6, R7, A, G, IR, Sum  : STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL Xreg, Yreg, Rin_control, Rout                  : STD_LOGIC_VECTOR(0 TO 7);
    SIGNAL AddSub, Hi, IRin, DIN_out, G_out, A_in, G_in   : STD_LOGIC ;
    SIGNAL Sel                                            : STD_LOGIC_VECTOR(0 TO 9);
    SIGNAL I                                              : STD_LOGIC_VECTOR(2 DOWNTO 0);
BEGIN
    
    Hi <= '1';
    I <= IR(8 DOWNTO 6);
    decX: dec3to8 PORT MAP(IR(5 DOWNTO 3), Hi, Xreg);   
    decY: dec3to8 PORT MAP(IR(2 DOWNTO 0), Hi, Yreg);

    statetable: PROCESS( Tstep_Q, Run, I)
    BEGIN
        CASE Tstep_Q IS
            WHEN T0 => -- data is loaded into IR in this time step
                IF (Run = '0') THEN
                    Tstep_D <= T0;
                ELSE 
                    Tstep_D <= T1;
                END IF; 
            -- other states
            WHEN T1 =>
                IF (I = "000") THEN
                    Tstep_D <= T0;
                ELSIF (I = "001") THEN
                     Tstep_D <= T0;
                ELSIF (I = "010") THEN
                     Tstep_D <= T2;
                ELSIF (I = "011") THEN
                     Tstep_D <= T2;
                END IF;
            WHEN T2 =>
                IF (I = "010") THEN
                     Tstep_D <= T3;
                ELSIF (I = "011") THEN
                     Tstep_D <= T3;
                END IF;
            WHEN T3 =>
                IF (I = "010") THEN
                     Tstep_D <= T0;
                ELSIF (I = "011") THEN
                     Tstep_D <= T0;
                END IF;
        END CASE;
    END PROCESS;

    controlsignals: PROCESS( Tstep_Q, I, Xreg, Yreg)
    BEGIN
        -- specify initial values
        IRin <= '0'; Rin_control <= "00000000"; Rout <= "00000000";
        Done <= '0'; DIN_out <= '0'; A_in <= '0'; G_in <= '0'; AddSub <= '0';
        G_out <= '0'; G_in <= '0';
        CASE Tstep_Q IS
            WHEN T0 =>                          -- store DIN in IR as long as Tstep_Q = 0
                IRin <= '1';
            WHEN T1 =>                          -- define signals in time step T1
                CASE I IS
                    WHEN "000" =>               -- we want to do mv I0 action
                        Rin_control <= Xreg;
                        Rout <= Yreg;
                        Done <= '1';
                    WHEN "001" =>               -- we want to do mvi
                        Rin_control <= Xreg;
                        Rout <= "00000000";
                        DIN_out <= '1';
                        Done <= '1';
                    WHEN "010" =>               -- we want to do add
                        Rout <= Xreg;
                        A_in <= '1';
                    WHEN "011" =>               -- we want to do sub
                        Rout <= Xreg;
                        A_in <= '1';
                    WHEN OTHERS => 
                        NULL;
                END CASE;
            WHEN T2 =>                          -- define signals in time step T2
                CASE I IS 
                    WHEN "010" =>               -- we want to do add
                        Rout <= Yreg;
                        G_in <= '1';
                    WHEN "011" =>               -- we want to do sub
                        Rout <= Yreg;
                        G_in <= '1';
                        AddSub <= '1';
                    WHEN OTHERS => 
                        NULL;
                END CASE;
            WHEN T3 =>                          -- define signals in time step T3
                CASE I IS 
                    WHEN "010" =>               -- we want to do add
                        Rin_control <= Xreg;
                        G_out <= '1';
                        Done <= '1';
                    WHEN "011" =>               -- we want to do sub
                        Rin_control <= Xreg;
                        G_out <= '1';
                        Done <= '1';
                    WHEN OTHERS => 
                        NULL;
                 END CASE;
        END CASE;
    END PROCESS;

    fsmflipflops: PROCESS( Clock, Resetn)
    BEGIN
        IF ((NOT Resetn) = '1') THEN
            Tstep_Q <= T0;
        ELSIF (Clock'EVENT AND Clock = '1') THEN
            Tstep_Q <= Tstep_D;
        END IF;
    END PROCESS;
	
    -- instantiate registers and the adder/subtracter unit
    reg_0: regn PORT MAP( BusWires, Rin_control(0), Clock, R0);
    reg_1: regn PORT MAP( BusWires, Rin_control(1), Clock, R1);
    reg_2: regn PORT MAP( BusWires, Rin_control(2), Clock, R2);
    reg_3: regn PORT MAP( BusWires, Rin_control(3), Clock, R3);
    reg_4: regn PORT MAP( BusWires, Rin_control(4), Clock, R4);
    reg_5: regn PORT MAP( BusWires, Rin_control(5), Clock, R5);
    reg_6: regn PORT MAP( BusWires, Rin_control(6), Clock, R6);
    reg_7: regn PORT MAP( BusWires, Rin_control(7), Clock, R7);
    reg_IR: regn PORT MAP( DIN, IRin, Clock, IR);
    
    -- register for adders
    reg_A: regn PORT MAP( BusWires, A_in, Clock, A);
    reg_G: regn PORT MAP( Sum, G_in, Clock, G);
    
    -- adder/subtractor
    adders: WITH AddSub SELECT 
              Sum <= A + BusWires WHEN '0',
                   A - BusWires WHEN OTHERS;
    -- define the bus / multiplexer
    Sel <= Rout & G_out & DIN_out;
    WITH Sel SELECT 
        BusWires <= DIN WHEN "0000000001",
                    G   WHEN "0000000010",
                    R7  WHEN "0000000100",
                    R6  WHEN "0000001000",
                    R5  WHEN "0000010000",
                    R4  WHEN "0000100000",
                    R3  WHEN "0001000000",
                    R2  WHEN "0010000000",
                    R1  WHEN "0100000000",
                    R0  WHEN "1000000000",
                    "000000000" WHEN OTHERS;
END Mixed;
