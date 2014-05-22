require "simple_initialize"
require "swissfork/bracket"

module Swissfork
  class ExchangedBracket < Swissfork::Bracket
    def initialize(players, difference)
      @players = exchanged_players(players, difference.s1_player, difference.s2_player)
    end

    def exchanged_players(players, player1, player2)
      index1, index2 = players.index(player1), players.index(player2)

      players.dup.tap do |new_players|
        new_players[index1], new_players[index2] = player2, player1
      end
    end
  end
end
