module Swissfork
  # Given a list of players to pair and possible opponents,
  # it calculates how many pairs can be generated.
  #
  # For example, if we've got players 1, 2, 3, 4, and 2 has
  # played against 3 and 4, and 3 and 4 have also played between
  # them, in theory all players have at least one possible
  # opponent and can be paired. However, if we pair number 2,
  # numbers 3 and 4 will remain unpaired, because their only
  # possible opponent (number 1) can't play against more than one
  # player.
  class PossiblePairs
    def initialize(players, opponents = players)
      @players = players
      @opponents = opponents
    end

    attr_reader :players, :opponents

    def count
      if players == opponents
        (players.count - incompatibilities) / 2
      else
        # Heterogeneous bracket. TODO: check if we can refactor it.
        players.count - incompatibilities
      end
    end

  private
    def incompatibilities
      return 0 if players.empty? || enough_players_to_guarantee_pairing?

      incompatibilities = obvious_incompatibilities

      until(players_in_a_combination > list.keys.count || enough_players_to_guarantee_pairing?)
        list.keys.combination(players_in_a_combination).each do |players|
          opponents = list.values_at(*players).reduce(&:+).uniq

          if opponents.count < players_in_a_combination
            remove_from_list(players + opponents)

            incompatibilities += players_in_a_combination - opponents.count
            reset_players_in_a_combination
            break
          elsif players_in_a_combination.odd? && (opponents - players).empty?
            remove_from_list(players + opponents)

            incompatibilities += 1
            reset_players_in_a_combination
            break
          end
        end

        increase_players_in_a_combination
      end

      incompatibilities + list.values.select { |rivals| rivals.empty? }.count
    end

    def list
      @list ||= players.reduce({}) do |list, player|
        list[player] = player.compatible_players_in(opponents)
        list
      end
    end

    def enough_players_to_guarantee_pairing?
      opponents.count >= players.count &&
      minimum_number_of_compatible_players >= (opponents - removals_list).count / 2
    end

    def minimum_number_of_compatible_players
      list.values.map(&:count).min
    end

    def remove_from_list(removals)
      removals.each { |player| list.delete(player) }
      list.each { |person, rivals| list[person] = rivals - removals }
      removals_list.push(*removals)
    end

    def removals_list
      @removals_list ||= []
    end

    def players_in_a_combination
      @players_in_a_combination ||= 1
    end

    def increase_players_in_a_combination
      @players_in_a_combination = players_in_a_combination + 1
    end

    def reset_players_in_a_combination
      @players_in_a_combination = 0
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
