require "simple_initialize"

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
      number_of_players_with_absolute_preference <= players.count / 2 &&
       players.count / 2.0 > players.map(&:opponents).map(&:count).max
    end

  protected
    def compatibility_list
      @compatibility_list ||= players.reduce({}) do |compatibility_list, player|
        compatibility_list[player] = opponents_for(player)
        compatibility_list
      end
    end

    def remove_from_list(removals)
      removals.each { |player| compatibility_list.delete(player) }
      compatibility_list.each do |person, rivals|
        compatibility_list[person] = rivals - removals
      end
    end

    def opponent_with_less_opponents_for(player)
      opponents_ordered_by_opponents_count.find do |opponent|
        compatibility_list[player].include?(opponent)
      end
    end

    def reset
      @compatibility_list = nil
    end

  private
    def incompatibilities
      reset

      if players.empty? || enough_players_to_guarantee_pairing?
        0
      else
        incompatibilities_by_least_compatible_pairing
      end
    end

    def opponents_for(player)
      player.compatible_players_in(players)
    end

    def players_ordered_by_opponents_count
      compatibility_list.keys.sort_by { |player| compatibility_list[player].count }
    end

    def opponents_ordered_by_opponents_count
      players_ordered_by_opponents_count
    end

    # Returns the number of incompatibilities found by pairing
    # the players with the least possible opponents with their
    # opponents with the least possible opponents.
    def incompatibilities_by_least_compatible_pairing
      incompatibilities = 0

      until players_ordered_by_opponents_count.empty?
        incompatibilities += incompatibilities_for(players_ordered_by_opponents_count.first)
      end

      incompatibilities
    end

    def incompatibilities_for(player)
      if compatibility_list[player].empty?
        1
      else
        0
      end.tap do
        remove_from_list([player, opponent_with_less_opponents_for(player)])
      end
    end

    def number_of_players_with_absolute_preference
      players_with_absolute_preference.group_by(&:colour_preference).values.map(&:count).max.to_i
    end

    def players_with_absolute_preference
      players.select do |player|
        player.preference_degree == :absolute && !player.topscorer?
      end
    end
  end
end
