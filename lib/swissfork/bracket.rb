require "swissfork/pair"
require "swissfork/exchanger"

module Swissfork
  # Handles the main pairing logic.
  #
  # A Bracket is generally made of players with the same score
  # or a similar one.
  #
  # The main method in this class is #pairs, which pairs its
  # players according to the rules described by FIDE.
  #
  # Objects from this class are useless, so the way to create
  # them is using Bracket.for(players), which creates an object
  # from either HomogeneousBracket or HeterogeneousBracket.
  class Bracket
    require "swissfork/quality_criterias"
    require "swissfork/heterogeneous_bracket"
    require "swissfork/homogeneous_bracket"

    include Comparable
    attr_reader :players

    def self.for(players)
      if new(players).homogeneous?
        HomogeneousBracket.new(players)
      else
        HeterogeneousBracket.new(players)
      end
    end

    def initialize(players)
      @players = players.sort
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
      all_players_have_the_same_points? || half_or_more_players_were_moved_down?
    end

    def heterogeneous?
      !homogeneous?
    end

    def number_of_possible_pairs
      @number_of_possible_pairs ||=
        (players.count - number_of_opponent_incompatibilities) / 2
    end

    def maximum_number_of_pairs
      players.count / 2
    end
    alias_method :max_pairs, :maximum_number_of_pairs # FIDE nomenclature

    def number_of_moved_down_players
      @number_of_moved_down_players ||= moved_down_players.count
    end
    alias_method :m0, :number_of_moved_down_players # FIDE nomenclature

    def number_of_moved_down_possible_pairs
      @number_of_moved_down_possible_pairs ||=
        moved_down_players.count - number_of_moved_down_opponent_incompatibilities
    end
    alias_method :m1, :number_of_moved_down_possible_pairs # FIDE nomenclature

    def number_of_required_pairs
      raise "Implement in subclass"
    end

    def number_of_players_in_s1
      number_of_required_pairs
    end
    alias_method :n1, :number_of_players_in_s1 # FIDE nomenclature

    def s1
      return [] if number_of_players_in_s1 < 1
      players[0..number_of_players_in_s1-1].sort
    end

    def s2
      (players - s1).sort
    end

    def s1_numbers
      s1.map(&:number)
    end

    def s2_numbers
      s2.map(&:number)
    end

    def unpairable_moved_down_players
      unpairable_players & moved_down_players
    end

    def exchange
      @players = exchanger.next_exchange
    end

    def exchanger
      @exchanger ||= Exchanger.new(s1, s2)
    end

    def pairs
      raise "Implement in subclass"
    end

    def leftovers
      raise "Implement in subclass"
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map(&:numbers)
    end

    def leftover_numbers
      leftovers.map(&:number)
    end

    def mark_established_pairs_as_impossible
      impossible_pairs << established_pairs
      clear_established_pairs
    end

  private
    def current_exchange_pairs
      clear_established_pairs

      while(!pairings_completed?)
        establish_pairs
        return nil if established_pairs.empty?

        if best_pairs_obtained?
          return definitive_pairs
        else
          mark_established_pairs_as_not_ideal
        end
      end
    end

    def establish_pairs
      s1.each do |player|
        pair = pair_for(player)
        # Not doing the quality check here decreases performance
        # dramatically.
        if pair && quality.s2_leftovers_can_downfloat?
          established_pairs << pair
        else
          return established_pairs
        end
      end
    end

    def best_pairs_obtained?
      raise "Implement in subclass"
    end

    def definitive_pairs
      raise "Implement in subclass"
    end

    def pair_for(player)
      opponents_for(player).map  { |opponent| Pair.new(player, opponent) }.select do |pair|
        !not_ideal_pairs.include?(established_pairs + [pair]) &&
        !impossible_pairs.include?(established_pairs + [pair])

      end.first
    end

    def opponents_for(player)
      player.compatible_players_in(s2).select do |opponent|
        !already_paired?(opponent)
      end
    end

    def pairable_players
      players.select { |player| player.compatible_players_in(players).any? }
    end

    def unpairable_players
      players - pairable_players
    end

    def pairings_completed?
      established_pairs.count == number_of_required_pairs
    end

    def established_pairs
      @established_pairs ||= []
    end

    def clear_established_pairs
      @established_pairs = nil
    end

    def not_ideal_pairs
      @not_ideal_pairs ||= []
    end

    def impossible_pairs
      @impossible_pairs ||= []
    end

    def mark_established_pairs_as_not_ideal
      not_ideal_pairs << established_pairs
      clear_established_pairs
    end

    def restart_pairs
      @not_ideal_pairs = nil
      clear_established_pairs
    end

    def reset_exchanger
      @exchanger = nil
      players.sort!
    end

    def already_paired?(player)
      established_pairs.any? { |pair| pair.include?(player) }
    end

    def still_unpaired_players
      players - established_pairs.map(&:players).flatten
    end

    def all_players_have_the_same_points?
      players.map(&:points).uniq.one?
    end

    def half_or_more_players_were_moved_down?
      number_of_moved_down_players >= players.length / 2
    end

    def moved_down_players
      players.select { |player| player.points > points }
    end

    def number_of_opponent_incompatibilities
      number_of_opponent_incompatibilities_for(players)
    end

    def number_of_moved_down_opponent_incompatibilities
      number_of_opponent_incompatibilities_for(moved_down_players)
    end

    def opponents_list(players, opponents)
      players.map do |player|
        player.compatible_players_in(opponents)
      end
    end

    def number_of_opponent_incompatibilities_for(players_to_pair)
      opponents_list = opponents_list(players_to_pair, players)

      opponents_list.uniq.reduce(0) do |incompatibilities, opponents|
        if opponents_list.count(opponents) > opponents.count
          incompatibilities + opponents_list.count(opponents) - opponents.count
        else
          incompatibilities
        end
      end
    end

    def best_possible_pairs?
      quality.ok?
    end

    def quality
      @quality ||= QualityCriterias.new(self)
    end
  end
end
