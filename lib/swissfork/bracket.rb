require "swissfork/player"

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
      @s1 ||= original_s1
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

    def exchange
      differences = s1.map do |s1_player|
        s2.map do |s2_player|
          { :s1_player => s1_player, :s2_player => s2_player, :difference => (s2_player.number - s1_player.number).abs }
        end
      end.flatten.sort do |players, other_players|
        if players[:difference] == other_players[:difference]
          other_players[:s1_player] <=> players[:s1_player]
        else
          players[:difference] <=> other_players[:difference]
        end
      end

      s1[s1.index(differences[exchanges][:s1_player])], s2[s2.index(differences[exchanges][:s2_player])] = s2[s2.index(differences[exchanges][:s2_player])], s1[s1.index(differences[exchanges][:s1_player])]

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
  end
end
