require "swissfork/player"
require "swissfork/players_difference"

module Swissfork
  class Bracket
    attr_reader :players

    def initialize(players)
      @players = players
    end

    def numbers
      players.map(&:number)
    end

    def homogeneous?
      players.map(&:points).uniq.one? || number_of_descended_players >= players.length / 2
    end

    def heterogeneous?
      !homogeneous?
    end

    def points
      players.map(&:points).min
    end

    def maximum_number_of_pairs
      players.length / 2
    end
    alias_method :p0, :maximum_number_of_pairs # FIDE nomenclature

    def number_of_descended_players
      @number_of_descended_players ||= players.select { |player| player.points > points }.length
    end
    alias_method :m0, :number_of_descended_players # FIDE nomenclature

    def possible_number_of_pairs
      maximum_number_of_pairs
    end
    alias_method :p1, :possible_number_of_pairs # FIDE nomenclature

    def pairable_descended_players
      number_of_descended_players
    end
    alias_method :m1, :pairable_descended_players # FIDE nomenclature

    def number_of_required_pairs
      if homogeneous?
        possible_number_of_pairs
      else
        pairable_descended_players
      end
    end
    alias_method :p, :number_of_required_pairs # FIDE nomenclature

    def s1
      @s1 ||= original_s1.dup
    end

    def s2
      @s2 ||= original_s2.dup
    end

    def s1_numbers
      s1.map(&:number)
    end

    def s2_numbers
      s2.map(&:number)
    end

    def transpose
      if s2 == transpositions.last
        exchange
      else
        self.s2 = transpositions[transpositions.index(s2) + 1]
      end
    end

    def exchange
      self.s1, self.s2 = next_exchange.s1, next_exchange.s2

      s1.sort!
      s2.sort!
    end

    def pairs
      while(!can_pair?)
        transpose
      end

      if homogeneous?
        regular_pairs
      else
        regular_pairs + Bracket.new(unpaired_players_after(regular_pairs)).pairs
      end
    end

    def can_pair?
      can_pair_regular? && (homogeneous? || Bracket.new(unpaired_players_after(regular_pairs)).can_pair?)
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map { |pair| pair.map(&:number) }
    end

    def unpaired_players
      unpaired_players_after(pairs)
    end

  private
    attr_writer :s1, :s2

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

    def original_s1
      players[0..number_of_required_pairs-1]
    end

    def original_s2
      players - original_s1
    end

    def transpositions
      @transpositions ||= {}
      @transpositions[s2.sort] ||= s2.sort.permutation.to_a
    end

    def exchanges
      @exchanges ||= differences.map do |difference|
        exchanged_bracket(difference.s1_player, difference.s2_player)
      end
    end

    def differences
      original_s1.product(original_s2).map do |players|
        PlayersDifference.new(*players)
      end.sort
    end

    def exchanged_bracket(player1, player2)
      Bracket.new(exchanged_players(player1, player2))
    end

    def exchanged_players(player1, player2)
      index1, index2 = players.index(player1), players.index(player2)

      players.dup.tap do |new_players|
        new_players[index1], new_players[index2] = player2, player1
      end
    end

    def next_exchange
      if s1.sort == original_s1.sort && s2.sort == original_s2.sort
        exchanges[0]
      else
        exchanges[exchanges.index(current_exchange) + 1]
      end
    end

    def current_exchange
      exchanges.select do |exchange|
        s1.sort == exchange.s1.sort && s2.sort == exchange.s2.sort
      end.first
    end

    def can_pair_regular?
      s1.map.with_index do |player, index|
        player.opponents.include?(s2[index])
      end.none?
    end

    def regular_pairs
      s1.map.with_index do |player, index|
        [player, s2[index]]
      end
    end

    def unpaired_players_after(pairs)
      players.select { |player| !pairs.flatten.include?(player) }
    end
  end
end
