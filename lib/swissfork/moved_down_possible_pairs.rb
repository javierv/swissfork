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
      minimum_number_of_compatible_players >= players.count
    end

    def opponents_ordered_by_opponents_count
      opponents.sort_by do |opponent|
        compatibility_list.values.select do |players|
          players.include?(opponent)
        end.count
      end
    end

  private
    def minimum_number_of_compatible_players
      compatibility_list.values.map(&:count).min.to_i
    end

    def opponents_for(player)
      player.compatible_opponents_in(opponents)
    end
  end
end
