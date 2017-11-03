require "swissfork/bracket"

module Swissfork
  # Handles the pairing of a homogeneous bracket.
  #
  # This class isn't supposed to be used directly; brackets
  # should be created using Bracket.for(players), which returns
  # either a homogeneous or a heterogeneous bracket.
  class HomogeneousBracket < Bracket
    def number_of_required_pairs
      number_of_possible_pairs
    end

    def s2
      players[number_of_players_in_s1..-1]
    end

    def resident_players
      players
    end

    def provisional_leftovers
      still_unpaired_players
    end

  private
    def exchanger
      @exchanger ||= Exchanger.new(s1, s2)
    end
  end
end
