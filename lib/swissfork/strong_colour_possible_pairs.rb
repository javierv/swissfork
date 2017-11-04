require "swissfork/generic_colour_possible_pairs"

module Swissfork
  # Calculates how many pairs can be obtained granting
  # the strong colour preferences of both players.
  class StrongColourPossiblePairs < GenericColourPossiblePairs

  private
    def opponents_for(player)
      super(player).select do |opponent|
        !player.colour_preference || !opponent.colour_preference ||
          player.colour_preference != opponent.colour_preference ||
          player.preference_degree == :mild || opponent.preference_degree == :mild
      end
    end
  end
end
