require "simple_initialize"

module Swissfork
  # This class isn't supposed to be used by other classes, with the
  # exception of the Bracket class.
  class ExchangedBracket < Swissfork::Bracket
    def initialize(players, difference)
      @players = exchanged_players(players, difference.s1_player, difference.s2_player)
      s1.sort!
      s2.sort!
    end

    def exchanged_players(players, player1, player2)
      index1, index2 = players.index(player1), players.index(player2)

      players.dup.tap do |new_players|
        new_players[index1], new_players[index2] = player2, player1
      end
    end

    def pairs
      pairs_without_exchange
    end
  end
end
