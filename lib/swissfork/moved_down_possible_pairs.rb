require "simple_initialize"
require "swissfork/possible_pairs"

module Swissfork
  # Given a list of players to pair and possible opponents,
  # it calculates how many players can be paired with those
  # opponents.
  class MovedDownPossiblePairs < PossiblePairs
    initialize_with :players, :opponents

    def count
      players.count - incompatibilities
    end

    def enough_players_to_guarantee_pairing?
      minimum_number_of_compatible_players >= list.keys.count
    end

  private
    def opponents_for(player)
      player.compatible_players_in(opponents)
    end
  end
end

