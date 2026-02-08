----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2026/02/07 18:03:40
-- Design Name: 
-- Module Name: main1_final - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main1_final is
    Port ( clk : in STD_LOGIC;
           btnC : in STD_LOGIC; --centre
           btnU : in STD_LOGIC; --up
           btnD : in STD_LOGIC; --down
           seg : out STD_LOGIC_VECTOR (6 downto 0);
           an : out STD_LOGIC_VECTOR (3 downto 0);
           dp : out STD_LOGIC);
end main1_final;

architecture Behavioral of main1_final is
    --2s pulse section 
    signal current_mode : STD_LOGIC := '0'; --0 is set, 1 is mode go
    constant mode_go : STD_LOGIC := '1';
    constant count_2s_max : integer := 200000000; --2s x 100MHz period
    signal timer_count : integer range 0 to count_2s_max := 0;
    signal tick_2s : STD_LOGIC := '0'; --pulse enable
    
    --time register 
    signal min_reg :integer range 0 to 60 :=10; --default 10 min
    signal sec_reg : integer range 0 to 59 :=0; --default 00s
    --debounce and connect with clean btn 
    signal btnC_clean, btnU_clean, btnD_clean : STD_LOGIC;
    --edge detection; reg to save btn stage for edge detection, btnX_edge is real useful btn signal
    signal btnC_reg, btnU_reg, btnD_reg :STD_LOGIC := '0';
    signal btnC_edge, btnU_edge, btnD_edge : STD_LOGIC;
    
    --divide min and sec number to tens and ones
    signal min_tens, min_ones, sec_tens, sec_ones : integer range 0 to 9;
    --scan counter, 16 bits, use 16 and 15 position to control seg display, when 0 to 14 bits are all full,then 15 and 16 position change
    signal scan_count : STD_LOGIC_VECTOR (16 DOWNTO 0) := (others => '0'); --(others => '0' to initialize
    --tens and ones current digital
    signal current_digital : integer range 0 to 9;
    
begin
    --connect with debounce part to btnX_clean
    DB_C : entity work.debounce port map(clk=>clk, btn_in=>btnC, btn_out=>btnC_clean);
    DB_U : entity work.debounce port map(clk=>clk, btn_in=>btnU, btn_out=>btnU_clean);
    DB_D : entity work.debounce port map(clk=>clk, btn_in=>btnD, btn_out=>btnD_clean);
    
    --divide min and sec 0-60 to tens and ones 
    min_tens <= min_reg / 10;
    min_ones <= min_reg mod 10;
    sec_tens <= sec_reg / 10;
    sec_ones <= sec_reg mod 10;
    
    --2s pulse section
    process(clk)
    begin
        if rising_edge(clk) then
            tick_2s <= '0';
            if current_mode = mode_go then --only mode go start sent 2s pulse
                if timer_count < count_2s_max - 1 then
                    timer_count <= timer_count + 1;
                else
                    tick_2s <='1';
                    timer_count <= 0;
                end if;
            else
                timer_count <= 0; --in mode set have no 2s  pulse
            end if;
        end if;
    end process;
    
    --control process 
    process(clk)
    begin
        if rising_edge (clk) then
            --about useful btn input; 1. connect btnreg and btnclean 
            btnC_reg <= btnC_clean;
            btnU_reg <= btnU_clean;
            btnD_reg <= btnD_clean;
            --then edge detection to catch only one pulse(1/100M=10ns) btn 
            btnC_edge <= btnC_clean and (not btnC_reg);
            btnU_edge <= btnU_clean and (not btnU_reg);
            btnD_edge <= btnD_clean and (not btnD_reg);
            
            --btn c to control mode
            if btnC_edge = '1' then
                current_mode <= not current_mode ;
            end if;
            
            --implement mode 
            if current_mode = '0' then  --set mode
                sec_reg <= 0; --whatever up down sec section is 0
                if btnU_edge = '1' then  --upbtn in set mode
                    if min_reg < 60 then min_reg <= min_reg + 1; end if;
                elsif btnD_edge = '1' then
                    if min_reg > 0 then min_reg <= min_reg - 1; end if;
                end if;
            else   --go mode
                if tick_2s = '1' then --count sec every 2s
                    if sec_reg = 0 then 
                        if min_reg /= 0 then min_reg <= min_reg - 1; sec_reg <=59; end if;
                    else --sec part is not 0
                        sec_reg <= sec_reg - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    --generate scanning frequency,because when 0 to 14 bits are all full,then 15 and 16 position change
    process(clk)
    begin
        if rising_edge (clk) then
            scan_count <= scan_count + 1;
         end if;
    end process;
    
    --select 4 segs and connect each tens and ones 
    process(min_tens, min_ones, sec_tens, sec_ones) --2^15=32768 ,then 32768x(1/100MHz)=327680ns=0.3ms 16,15 bits from 00 to 11 use 0.3ms x 4 = 1.2ms
    begin
        case scan_count (16 DOWNTO 15) is 
            when "00" =>  an <= "0111"; current_digital <= min_tens; --left1
            when "01" =>  an <= "1011"; current_digital <= min_ones; --left2
            when "10" =>  an <= "1101"; current_digital <= sec_tens; --left3
            when "11" =>  an <= "1110"; current_digital <= sec_tens; --left4
            when others => an<="1111"; current_digital <=0;
        end case;
    end process;
    
    --display seg 
    process(current_digital )
    begin
        case current_digital is 
            when 0 =>    seg<="1000000";
            when 1 =>    seg<="1111001";
            when 2 =>    seg<="0100100";
            when 3 =>    seg<="0110000";
            when 4 =>    seg<="0011001";
            when 5 =>    seg<="0010010";
            when 6 =>    seg<="0000010";
            when 7 =>    seg<="1111000";
            when 8 =>    seg<="0000000";
            when 9 =>    seg<="0010000";
            when others =>    seg<="1111111";
        end case;
    end process;
    
    --decimal point display; when set mode it is off, at go mode it is on 
    dp <= '1' when current_mode = '0' else '0'; 
    
end Behavioral;
