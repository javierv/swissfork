require "simple_initialize"

module Swissfork
  # Calculates and compares the differences in a exchange.
  #
  # It follows the priority criterias as defined in FIDE
  # Dutch System D.2.b, D.2.c and D.2.d.
  class ExchangesDifference
    include Comparable

    initialize_with :s1_players, :s2_players

    def <=>(other_difference)
      [difference, other_difference.s1_numbers.sort.reverse, s2_numbers.sort] <=>
      [other_difference.difference, s1_numbers.sort.reverse, other_difference.s2_numbers.sort]
    end

    def difference
      (s1_numbers.sum - s2_numbers.sum).abs
    end

    def s1_numbers
      s1_players.map(&:bsn)
    end

    def s2_numbers
      s2_players.map(&:bsn)
    end
  end
end
