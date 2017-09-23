require "swissfork/players_difference"
require "swissfork/pair"

module Swissfork
  class Bracket
    require "swissfork/exchanged_bracket"
    require "swissfork/heterogeneous_bracket"

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
      players.reject! { |player| unpaired_players.include?(player) }
    end

    def move_players_to_allow_pairs_for(bracket)
      number_of_players = bracket.unpaired_players.count

      if(number_of_players > 1)
        moved_players = players[(-1 * number_of_players)..-1]
        bracket.add_players(moved_players)
        players.reject! { |player| moved_players.include?(player) }
      end
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
      if heterogeneous?
        return HeterogeneousBracket.new(players).pairs
      end

      if pairs_without_exchange
        pairs_without_exchange
      elsif exchanges.map(&:pairs).compact.first
        exchanges.map(&:pairs).compact.first
      else
        if failure_criterias.empty?
          []
        else
          failure_criterias.pop
          restart_pairs
          pairs
        end
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
        establish_pairs
        return nil if established_pairs.empty?

        if definitive_pairs_obtained?
          return definitive_pairs
        else
          mark_established_pairs_as_impossible
        end
      end
    end

    def establish_pairs
      s1.each do |player|
        if pair_for(player)
          established_pairs << pair_for(player)
        else
          return nil
        end
      end
    end

    def definitive_pairs_obtained?
      pairings_completed? && best_possible_pairs?
    end

    def definitive_pairs
      established_pairs
    end

    def pair_for(s1_player)
      players_for(s1_player).map  { |s2_player| Pair.new(s1_player, s2_player) }.select do |pair|
        !impossible_pairs.include?(established_pairs + [pair])
      end.first
    end

    def players_for(s1_player)
      s2.select do |s2_player|
        s1_player.compatible_with?(s2_player) && !already_paired?(s2_player)
      end
    end

    def pairings_completed?
      established_pairs.count == s1.count
    end

    def established_pairs
      @established_pairs ||= []
    end

    def reset_pairs
      @established_pairs = []
      @s1 = nil
      @s2 = nil
    end

    def impossible_pairs
      @impossible_pairs ||= []
    end

    def restart_pairs
      @impossible_pairs = []
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

    def best_possible_pairs?
      failure_criterias.none? { |condition| send(condition) }
    end

    def failure_criterias
      @failure_criterias ||= [
        :any_players_descending_twice?,
        :same_downfloats_as_previous_round?,
        :same_upfloats_as_previous_round?,
        :same_downfloats_as_two_rounds_ago?,
        :same_upfloats_as_two_rounds_ago?
      ]
    end

    def any_players_descending_twice?
      unpaired_players_after(established_pairs).any? do |player|
        player.points > points
      end
    end

    def same_downfloats_as_previous_round?
      unpaired_players_after(established_pairs).any? do |player|
        player.descended_in_the_previous_round?
      end
    end

    def same_upfloats_as_previous_round?
      ascending_players.any? do |player|
        player.ascended_in_the_previous_round?
      end
    end

    def same_downfloats_as_two_rounds_ago?
      unpaired_players_after(established_pairs).any? do |player|
        player.descended_two_rounds_ago?
      end
    end

    def same_upfloats_as_two_rounds_ago?
      ascending_players.any? do |player|
        player.ascended_two_rounds_ago?
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
