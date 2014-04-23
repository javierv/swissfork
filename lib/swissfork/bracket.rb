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
      players - original_s1
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
      self.s1, self.s2 = next_exchange[0], next_exchange[1]

      s1.sort!
      s2.sort!
    end

    def maximum_number_of_pairs
      players.length / 2
    end
    alias_method :p0, :maximum_number_of_pairs # FIDE nomenclature

  private
    attr_writer :s1, :s2, :transpositions

    def transpositions
      @transpositions ||= 0
    end

    def exchanges
      differences.map do |difference|
        [
          original_s1.dup.tap { |new_s1| new_s1[new_s1.index(difference.s1_player)] = difference.s2_player },
          original_s2.dup.tap { |new_s2| new_s2[original_s2.index(difference.s2_player)] = difference.s1_player }
        ]
      end
    end

    def differences
      original_s1.product(original_s2).map do |players|
        PlayersDifference.new(*players)
      end.sort
    end

    def next_exchange
      if s1 == original_s1 && s2 == original_s2
        exchanges[0]
      else
        exchanges[exchanges.index(exchanges.select { |exchange| s1.sort == exchange[0].sort && s2.sort == exchange[1].sort }.first) + 1]
      end
    end

    def s1_numbers=(numbers)
      self.s1 = players_with(numbers)
    end

    def s2_numbers=(numbers)
      self.s2 = players_with(numbers)
    end

    def players_with(numbers)
      numbers.map { |number| player_with(number) }
    end

    def player_with(number)
      players.select { |player| player.number == number }.first
    end
  end
end
