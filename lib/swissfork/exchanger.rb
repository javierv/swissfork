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
      exchanges_count >= differences_with_one_player.count - 1
    end

    # Helper methods to make tests easier
    def numbers
      exchanged_players.map(&:number)
    end

  private
    def exchanged_players
      exchange(differences[exchanges_count - 1].s1_players,
               differences[exchanges_count - 1].s2_players)
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
      if exchanges_count <= differences_with_one_player.count
        differences_with_one_player
      else
        differences_with_one_player + differences_with_two_players
      end
    end

    def differences_with_one_player
      s1.combination(1).to_a.product(s2.combination(1).to_a).map do |players|
        PlayersDifference.new(*players)
      end.sort
    end

    def differences_with_two_players
      s1.combination(2).to_a.product(s2.combination(2).to_a).map do |players|
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

    def players
      s1 + s2
    end
  end
end
