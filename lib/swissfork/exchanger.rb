require "simple_initialize"
require "swissfork/players_difference"

module Swissfork
  # Handles exchanges of players between S1 and S2 in
  # homogeneous brackets, as described in FIDE system,
  # section D.2
  class Exchanger
    initialize_with :s1, :s2

    def next
      increase_exchanges_count
      exchanged_players
    end

    def limit_reached?
      number_of_players_in_a_exchange >= s1.count &&
        exchanges_count >= differences.count - 1
    end

    # Helper methods to make tests easier
    def numbers
      exchanged_players.map(&:number)
    end

  private
    def exchanged_players
      exchange(current_difference.s1_players, current_difference.s2_players)
    end

    def current_difference
      differences[exchanges_count - 1]
    end

    def exchange(first_players, second_players)
      players.dup.tap do |new_players|
        first_players.each.with_index do |first_player, index|
          second_player = second_players[index]

          first_index, second_index =
            players.index(first_player), players.index(second_player)

          new_players[first_index], new_players[second_index] =
            second_player, first_player
        end
      end
    end

    def differences
      if exchanges_count > current_differences.count
        increase_number_of_players_in_a_exchange
      end

      current_differences
    end

    def current_differences
      @current_differences ||= (1..number_of_players_in_a_exchange).reduce([]) do |differences, n|
        differences + differences_with_n_players(n)
      end
    end

    def differences_with_n_players(n)
      s1.combination(n).to_a.product(s2.combination(n).to_a).map do |players|

        PlayersDifference.new(*players)
      end.sort
    end

    def exchanges_count
      @exchanges_count ||= 0
    end

    def increase_exchanges_count
      @exchanges_count ||= 0
      @exchanges_count += 1
    end

    def number_of_players_in_a_exchange
      @number_of_players_in_a_exchange ||= 1
    end

    def increase_number_of_players_in_a_exchange
      @number_of_players_in_a_exchange ||= 1
      @number_of_players_in_a_exchange += 1
      @current_differences = nil
    end

    def players
      s1 + s2
    end
  end
end
