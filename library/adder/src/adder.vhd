library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
    Port (
        a    : in  STD_LOGIC_VECTOR (3 downto 0);  -- First 4-bit input
        b    : in  STD_LOGIC_VECTOR (3 downto 0);  -- Second 4-bit input
        s    : out STD_LOGIC_VECTOR (3 downto 0)   -- 4-bit sum
    );
end adder;

architecture Behavioral of adder is
begin
    process(a, b) begin
        s <= STD_LOGIC_VECTOR(signed(a) + signed(b));
    end process;
end Behavioral;