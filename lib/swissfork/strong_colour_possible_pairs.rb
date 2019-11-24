require "swissfork/generic_colour_possible_pairs"

module Swissfork
  # Calculates how many pairs can be obtained granting
  # the strong colour preferences of both players.
  class StrongColourPossiblePairs < GenericColourPossiblePairs
    private

      def opponents_for(player)
        player.compatible_strong_colours_in(players)
      end
  end
end
