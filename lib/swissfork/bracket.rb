require "swissfork/players_difference"
require "swissfork/pair"
require "simple_initialize"

module Swissfork
  class Bracket
    initialize_with :players

    def numbers
      players.map(&:number)
    end

    def points
      players.map(&:points).min
    end

    # We don't include Comparable because it would override
    # the == method, and that would break the next_exchange method.
    def <=>(bracket)
      bracket.points <=> points
    end

    def homogeneous?
      all_players_have_the_same_points? || half_or_more_players_were_descended?
    end

    def heterogeneous?
      !homogeneous?
    end

    def maximum_number_of_pairs
      players.length / 2
    end
    alias_method :p0, :maximum_number_of_pairs # FIDE nomenclature

    def number_of_descended_players
      @number_of_descended_players ||= descended_players.length
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

    def exchange
      @s1, @s2 = next_exchange.s1.sort, next_exchange.s2.sort
    end

    def pairs
      return [] if players.empty? || players.one?

      while(!bracket_pairs)
        if next_exchange
          exchange
        else
          return nil
        end
      end

      bracket_pairs
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map(&:numbers)
    end

    def unpaired_players
      unpaired_players_after(pairs)
    end

  private
    def s1_numbers=(numbers)
      @s1 = players_with(numbers)
    end

    def s2_numbers=(numbers)
      @s2 = players_with(numbers)
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

    def bracket_pairs
      reset_pairs

      while(!pairings_completed?)
        s1.each do |player|
          if pair_for(player)
            established_pairs << pair_for(player)
          else
            return nil if established_pairs.empty?
            mark_established_pairs_as_impossible
            break
          end
        end

        if pairings_completed? && heterogeneous?
          if leftover_pairs
            return established_pairs + leftover_pairs
          else
            mark_established_pairs_as_impossible
          end
        end
      end

      established_pairs
    end

    def leftover_pairs
      Bracket.new(unpaired_players_after(established_pairs)).pairs
    end

    def pair_for(s1_player)
      s2.map { |s2_player| Pair.new(s1_player, s2_player) }.select do |pair|
        pair.compatible? && !already_paired?(pair.s2_player) && !impossible_pairs.include?(established_pairs + [pair])
      end.first
    end

    def pairings_completed?
      established_pairs.count == s1.count
    end

    def established_pairs
      @established_pairs ||= []
    end

    def reset_pairs
      @established_pairs = []
    end

    def impossible_pairs
      @impossible_pairs ||= []
    end

    def mark_established_pairs_as_impossible
      impossible_pairs << established_pairs
      reset_pairs
    end

    def already_paired?(player)
      established_pairs.any? { |pair| pair.include?(player) }
    end

    def unpaired_players_after(pairs)
      players.select { |player| pairs.none? { |pair| pair.include?(player) }}
    end

    def all_players_have_the_same_points?
      players.map(&:points).uniq.one?
    end

    def half_or_more_players_were_descended?
      number_of_descended_players >= players.length / 2
    end

    def descended_players
      players.select { |player| player.points > points }
    end
  end
end
