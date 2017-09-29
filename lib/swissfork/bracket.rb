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
  class Bracket
    require "swissfork/heterogeneous_bracket"
    require "swissfork/quality_criterias"

    include Comparable
    attr_reader :players

    def initialize(players)
      @players = players.sort
    end

    def add_player(player)
      @players = (players << player).sort
    end

    def add_players(players)
      players.each { |player| add_player(player) }
    end

    def move_leftover_players_to(bracket)
      bracket.add_players(leftover_players)
      players.reject! { |player| leftover_players.include?(player) }
    end

    def move_players_to_allow_pairs_for(bracket)
      number_of_players = bracket.leftover_players.count

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
      all_players_have_the_same_points? || half_or_more_players_were_moved_down?
    end

    def heterogeneous?
      !homogeneous?
    end

    def maximum_number_of_pairs
      players.count / 2
    end
    alias_method :p0, :maximum_number_of_pairs # FIDE nomenclature

    def number_of_moved_down_players
      @number_of_moved_down_players ||= moved_down_players.count
    end
    alias_method :m0, :number_of_moved_down_players # FIDE nomenclature

    def possible_number_of_pairs
      maximum_number_of_pairs
    end
    alias_method :p1, :possible_number_of_pairs # FIDE nomenclature

    def number_of_pairable_moved_down_players
      number_of_moved_down_players
    end
    alias_method :m1, :number_of_pairable_moved_down_players # FIDE nomenclature

    def number_of_required_pairs
      if homogeneous?
        possible_number_of_pairs
      else
        number_of_pairable_moved_down_players
      end
    end
    alias_method :p, :number_of_required_pairs # FIDE nomenclature

    def s1
      players[0..number_of_required_pairs-1].sort
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

    def pairs
      if heterogeneous?
        HeterogeneousBracket.new(players).pairs
      else
        homogeneous_pairs
      end
    end

    def homogeneous_pairs
      while(!current_exchange_pairs)
        if exchanger.limit_reached?
          if quality.worst_possible?
            return []
          else
            quality.be_more_permissive
            restart_pairs
            players.sort!
          end
        else
          exchange
          restart_pairs
        end
      end

      current_exchange_pairs
    end

    def exchange
      @players = exchanger.next_exchange
    end

    def exchanger
      @exchanger ||= Exchanger.new(s1, s2)
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map(&:numbers)
    end

    def leftover_players
      pairs && still_unpaired_players
    end

    def mark_established_pairs_as_impossible
      impossible_pairs << established_pairs
      clear_established_pairs
    end

  private
    def current_exchange_pairs
      return definitive_pairs if @bracket_already_paired
      clear_established_pairs

      while(!pairings_completed?)
        establish_pairs
        return nil if established_pairs.empty?

        if best_pairs_obtained?
          @bracket_already_paired = true
          return definitive_pairs
        else
          mark_established_pairs_as_impossible
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
          return nil
        end
      end
    end

    def best_pairs_obtained?
      pairings_completed? && best_possible_pairs?
    end

    def definitive_pairs
      established_pairs
    end

    def pair_for(player)
      opponents_for(player).map  { |opponent| Pair.new(player, opponent) }.select do |pair|
        !impossible_pairs.include?(established_pairs + [pair])
      end.first
    end

    def opponents_for(player)
      s2.select do |opponent|
        player.compatible_with?(opponent) && !already_paired?(opponent)
      end
    end

    def players_compatible_for(player)
      players.select { |opponent| player.compatible_with?(opponent) }
    end

    def pairable_players
      players.select { |player| players_compatible_for(player).any? }
    end

    def pairings_completed?
      established_pairs.count == pairable_players.count / 2
    end

    def established_pairs
      @established_pairs ||= []
    end

    def clear_established_pairs
      @established_pairs = nil
      @bracket_already_paired = false
    end

    def impossible_pairs
      @impossible_pairs ||= []
    end

    def restart_pairs
      @impossible_pairs = nil
      clear_established_pairs
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

    def best_possible_pairs?
      quality.ok?
    end

    def quality
      @quality ||= QualityCriterias.new(self)
    end
  end
end
