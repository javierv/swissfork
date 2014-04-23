require "swissfork/player"
require "swissfork/players_difference"

module Swissfork
  class Bracket
    attr_reader :players

    def initialize(players)
      @players = players
    end

    def original_s1
      players[0..maximum_number_of_pairs-1]
    end

    def original_s2
      players - s1
    end

    def s1
      @s1 ||= original_s1.dup
    end

    def s2
      @s2 ||= original_s2.dup
    end

    def numbers
      players.map(&:number)
    end

    def s1_numbers
      s1.map(&:number)
    end

    def s2_numbers
      s2.map(&:number)
    end

    def transpose
      self.s2 = original_s2.permutation.to_a[transpositions + 1]
      self.transpositions = transpositions + 1
    end

    def exchange
      s1[current_s1_exchange], s2[current_s2_exchange] = s2[current_s2_exchange], s1[current_s1_exchange]

      s1.sort!
      s2.sort!
      self.exchanges = exchanges + 1
    end

    def maximum_number_of_pairs
      players.length / 2
    end
    alias_method :p0, :maximum_number_of_pairs # FIDE nomenclature

  private
    attr_writer :s2, :transpositions, :exchanges

    def transpositions
      @transpositions ||= 0
    end

    def exchanges
      @exchanges ||= 0
    end

    def differences
      original_s1.product(original_s2).map do |players|
        PlayersDifference.new(*players)
      end.sort
    end

    def current_s1_exchange
      s1.index(differences[exchanges].s1_player)
    end

    def current_s2_exchange
      s2.index(differences[exchanges].s2_player)
    end
  end
end
