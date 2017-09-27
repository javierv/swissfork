require "simple_initialize"

module Swissfork
  class PlayersDifference
    include Comparable

    initialize_with :s1_players, :s2_players

    def <=>(other_difference)
      if difference == other_difference.difference
        if s1_numbers.sort.reverse == other_difference.s1_numbers.sort.reverse
          s2_numbers.sort <=> other_difference.s2_numbers.sort
        else
          other_difference.s1_numbers.sort.reverse <=> s1_numbers.sort.reverse
        end
      else
        difference <=> other_difference.difference
      end
    end

    def difference
      (s1_players.map(&:bsn).sum - s2_players.map(&:bsn).sum).abs
    end

    def inspect
      [s1_numbers, s2_numbers]
    end

    def s1_numbers
      s1_players.map(&:bsn)
    end

    def s2_numbers
      s2_players.map(&:bsn)
    end
  end
end
