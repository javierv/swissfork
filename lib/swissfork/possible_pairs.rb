require "simple_initialize"
require "set"

module Swissfork
  # Given a list of players to pair, it calculates how many pairs
  # can be generated.
  #
  # For example, if we've got players 1, 2, 3, 4, and 2 has
  # played against 3 and 4, and 3 and 4 have also played between
  # them, in theory all players have at least one possible
  # opponent and can be paired. However, if we pair number 2,
  # numbers 3 and 4 will remain unpaired, because their only
  # possible opponent (number 1) can't play against more than one
  # player.
  class PossiblePairs
    initialize_with :players

    def count
      @count ||= (players.count - incompatibilities) / 2
    end

    def enough_players_to_guarantee_pairing?
      minimum_number_of_compatible_players >= list.keys.count / 2
    end

    def self.for(players)
      possible_pairs[players.to_set] ||= new(players)
    end

    def self.possible_pairs
      @possible_pairs ||= {}
    end

  private
    def incompatibilities
      return 0 if players.empty? || enough_players_to_guarantee_pairing?

      obvious_incompatibilities + incompatibilities_by_least_compatible_pairing
    end

    def list
      @list ||= players.reduce({}) do |list, player|
        list[player] = opponents_for(player)
        list
      end
    end

    def opponents_for(player)
      player.compatible_players_in(players)
    end

    def minimum_number_of_compatible_players
      list.values.map(&:count).min.to_i
    end

    def remove_from_list(removals)
      removals.each { |player| list.delete(player) }
      list.each { |person, rivals| list[person] = rivals - removals }
    end

    def opponent_with_less_opponents_for(player)
      opponents_ordered_by_opponents_count.each do |opponent|
        return opponent if list[player].include?(opponent)
      end
    end

    def players_ordered_by_opponents_count
      list.keys.sort_by { |player| list[player].count }
    end

    def opponents_ordered_by_opponents_count
      players_ordered_by_opponents_count
    end

    # Finds players with no opponents, or players with the
    # same possible opponents.
    #
    # For example, if it finds player 1 is only compatible
    # with player 5, player 2 is only compatible with
    # player 5, and player 3 is also compatible just with
    # player 5, it removes all four players from the list and
    # adds two incompatibilities.
    def obvious_incompatibilities
      repetition_list.reduce(0) do |incompatibilities, (opponents, count)|
        if count >= opponents.count
          incompatibilities += count - opponents.count
          remove_from_list(list.keys.select { |player| list[player] == opponents} + opponents)
        end

        incompatibilities
      end
    end

    # Returns the number of incompatibilities found by pairing
    # the players with the lest possible opponents with their
    # opponents with the least possible opponents.
    def incompatibilities_by_least_compatible_pairing
      incompatibilities = 0

      until enough_players_to_guarantee_pairing?
        player = players_ordered_by_opponents_count.first

        if list[player].empty?
          incompatibilities += 1
          remove_from_list([player])
        else
          remove_from_list([player, opponent_with_less_opponents_for(player)])
        end
      end

      incompatibilities
    end

    # Hash with the following format:
    # array_of_opponents => number_of_players_having_those_opponents_as_compatible
    def repetition_list
      @repetition_list ||= list.values.inject(Hash.new(0)) do |repetition_list, opponents|
        repetition_list[opponents] += 1
        repetition_list
      end
    end
  end
end
