require "swissfork/player"

module Swissfork
  class Bracket
    attr_reader :players

    def initialize(players)
      @players = players
    end

    def s1
      players[0..maximum_number_of_pairs-1]
    end

    def original_s2
      players - s1
    end

    def s2
      @s2 ||= original_s2
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

    def maximum_number_of_pairs
      players.length / 2
    end
    alias_method :p0, :maximum_number_of_pairs # FIDE nomenclature

  private
    attr_writer :s2

    def transpositions
      @transpositions ||= 0
    end
    attr_writer :transpositions
  end
end
