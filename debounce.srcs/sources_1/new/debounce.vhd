----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2026/02/07 12:05:48
-- Design Name: 
-- Module Name: debounce - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL; --because +
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity debounce is
    Port ( clk : in STD_LOGIC;
           btn_in : in STD_LOGIC;
           btn_out : out STD_LOGIC);
end debounce;

architecture Behavioral of debounce is --set debounce time is 20ms, 20msx100MHz=2000000
    constant count_max :integer :=2000000; --2000000 period means 20ms
    signal count : integer range 0 to count_max := 0;
    signal stable_btn: STD_LOGIC := '0';
begin
    process(clk)
    begin
        if rising_edge (clk) then
            if btn_in /= stable_btn  then --knob down
                if count < count_max then
                    count <= count + 1;
                else
                    stable_btn <= btn_in; --count enough 2000000, is 20ms, complete debounce
                    count <= 0; --reset count
                end if;
            else
                count <= 0; --not knob down,count remains 0
            end if;
        end if;
    end process;
    btn_out <= stable_btn ;

end Behavioral;
