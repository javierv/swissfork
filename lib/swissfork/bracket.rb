require "swissfork/players_difference"
require "swissfork/pair"

module Swissfork
  class Bracket
    require "swissfork/exchanged_bracket"

    include Comparable
    attr_reader :players

    def initialize(players)
      @players = players.sort
    end

    def add_player(player)
      @players = (players << player).sort
      @s1, @s2 = nil
    end

    def add_players(players)
      players.each { |player| add_player(player) }
    end

    def move_unpaired_players_to(bracket)
      bracket.add_players(unpaired_players)
    end

    def numbers
      players.map(&:number)
    end

    def points
      players.map(&:points).min
    end

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

    def pairs
      return [] if players.empty? || players.one?

      if pairs_without_exchange
        pairs_without_exchange
      elsif homogeneous?
        exchanges.map(&:pairs).compact.first
      end
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map(&:numbers)
    end

    def exchanges
      differences.map do |difference|
        ExchangedBracket.new(players, difference)
      end
    end

    def unpaired_players
      unpaired_players_after(pairs)
    end

    def mark_established_pairs_as_impossible
      impossible_pairs << established_pairs
      reset_pairs
    end

  private
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

    def differences
      original_s1.product(original_s2).map do |players|
        PlayersDifference.new(*players)
      end.sort
    end

    def pairs_without_exchange
      reset_pairs

      while(!pairings_completed?)
        s1.each do |player|
          if pair_for(player)
            established_pairs << pair_for(player)
          else
            # TODO: reduce pairing criteria and try again
            return nil if established_pairs.empty?
            mark_established_pairs_as_impossible
            break
          end
        end

        if pairings_completed?
          if heterogeneous?
            if leftover_pairs && best_possible_pairs?
              return established_pairs + leftover_pairs
            else
              mark_established_pairs_as_impossible
            end
          else
            mark_established_pairs_as_impossible unless best_possible_pairs?
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

    def best_possible_pairs?
      !already_descended_players? && !already_ascended_players?
    end

    def already_descended_players?
      unpaired_players_after(established_pairs).any? do |player|
        player.has_descended?
      end
    end

    def already_ascended_players?
      ascending_players.any? do |player|
        player.has_ascended?
      end
    end

    def ascending_players
      heterogeneous_pairs.map(&:s2_player)
    end

    def heterogeneous_pairs
      established_pairs.select do |pair|
        pair.s1_player.points != pair.s2_player.points
      end
    end
  end
end
