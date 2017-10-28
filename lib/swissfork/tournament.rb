require "simple_initialize"
require "swissfork/round"
require "swissfork/player"
require "swissfork/unpaired_game"

module Swissfork
  class Tournament
    initialize_with :number_of_rounds
    attr_reader :players

    def name
      "Championship" # TODO
    end

    def add_inscription(inscription)
      inscriptions.push(inscription)
    end

    def rounds
      @rounds ||= []
    end

    def current_round
      rounds.last
    end

    def pairs
      current_round.pairs
    end

    def pair_numbers
      # Hack because the helper method returns wrong colours during the
      # first round.
      pairs.map { |pair| pair.players.map(&:number) }
    end

    def start
      assign_player_numbers
    end

    def start_round
      # TODO: raise exception if there are no more rounds allowed and if the
      # current round isn't finished.
      assign_player_numbers unless players
      set_topscorers

      rounds << Round.new(players - non_paired_players).tap { |round| round.number = rounds.count + 1 }
    end

    def finish_round(results)
      current_round.results = results

      non_paired_players.each do |player|
        player.add_game(
          UnpairedGame.new(player, points: unpaired_points[player.number])
        )
      end

      @unpaired_points = nil
    end

    def assign_player_numbers
      @players = inscriptions.sort.map.with_index do |inscription, index|
        Player.new(index + 1).tap do |player|
          player.inscription = inscription
        end
      end
    end

    # Players notifying they won't be paired before the start of the next
    # round. It accepts an enumerable, and each element can be either an
    # interger representing the number of the unpaired player, or a hash with
    # the key representing the number of the unpaired player and the value
    # representing how many points the player will get.
    #
    # Examples:
    #
    # #non_paired_numbers = [1, 2, 3]
    # Players 1, 2, and 3 won't be paired and will be given the default points
    # given to unpaired players.
    #
    # #non_paired_numbers = [1, { 2 => 0, 3 => 1 }, 4]
    # Players 1 and 4 will be given the default points given to unpaired players,
    # player 3 will be given one point and player 2 will be given no points.
    def non_paired_numbers=(numbers)
      @unpaired_points = numbers.reduce({}) do |unpaired_points, number_or_numbers|
        if number_or_numbers.is_a?(Hash)
          number_or_numbers.each do |number, points|
            unpaired_points[number] = points
          end
        else
          unpaired_points[number_or_numbers] = points_given_to_unpaired_players
        end

        unpaired_points
      end
    end

    def points_given_to_unpaired_players
      @points_given_to_unpaired_players || default_points_given_to_unpaired_players
    end
    attr_writer :points_given_to_unpaired_players

    def topscorers
      if last_round?
        players.select { |player| player.points > (rounds.count / 2.0) }
      else
        []
      end
    end

  private
    def non_paired_players
      @non_paired_players = unpaired_points.keys.map { |number| players[number - 1] }
    end

    def default_points_given_to_unpaired_players
      if last_round?
        0
      else
        0.5
      end
    end

    def set_topscorers
      topscorers.each { |player| player.topscorer = true }
    end

    def last_round?
      (rounds.count >= number_of_rounds - 1) &&
        rounds[number_of_rounds - 2].finished?
    end

    def unpaired_points
      @unpaired_points ||= {}
    end

    def inscriptions
      @inscriptions ||= []
    end
  end
end
