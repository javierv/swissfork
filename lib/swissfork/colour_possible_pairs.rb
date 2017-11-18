require "swissfork/generic_colour_possible_pairs"

module Swissfork
  # Calculates how many pairs can be obtained granting
  # the colour preferences of both players.
  class ColourPossiblePairs < GenericColourPossiblePairs

  private
    def opponents_for(player)
      player.compatible_colours_in(players)
    end
  end
end
