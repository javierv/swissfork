require "swissfork/homogeneous_bracket"

module Swissfork
  # This class isn't supposed to be used by other classes, with the
  # exception of the HeterogeneousBracket class.
  class Remainder < HomogeneousBracket
    def number_of_players_in_s1
      maximum_number_of_pairs
    end

  private
    # TODO: write failing test for the case when the homogeneous bracket
    # is impossible to pair
    def pairings_completed?
      established_pairs.count == s1.count
    end
  end
end
