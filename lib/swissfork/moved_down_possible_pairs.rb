require "simple_initialize"
require "swissfork/possible_pairs"

module Swissfork
  # Given a list of players to pair and possible opponents,
  # it calculates how many players can be paired with those
  # opponents.
  class MovedDownPossiblePairs < PossiblePairs
    initialize_with :players, :opponents

    def count
      players.size - incompatibilities
    end

    def enough_players_to_guarantee_pairing?
      minimum_number_of_compatible_players >= players.size
    end

    def opponents_ordered_by_opponents_count
      # TODO: write test. Right now everything passes if we change it to
      # opponents
      opponents.sort_by do |opponent|
        compatibility_list.values.count { |players| players.include?(opponent) }
      end
    end

  private
    def minimum_number_of_compatible_players
      compatibility_list.values.map(&:size).min.to_i
    end

    def opponents_for(player)
      player.compatible_opponents_in(opponents)
    end
  end
end
