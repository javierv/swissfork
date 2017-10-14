require "swissfork/pair"
require "swissfork/exchanger"
require "set"

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
    require "swissfork/opponents_incompatibilities"

    include Comparable
    attr_reader :players
    attr_writer :number_of_required_downfloats

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
      @points ||= players.map(&:points).min
    end

    def <=>(bracket)
      bracket.points <=> points
    end

    def homogeneous?
      all_players_have_the_same_points?
    end

    def number_of_possible_pairs
      [maximum_number_of_pairs, number_of_compatible_pairs].min
    end

    def maximum_number_of_pairs
      (players.count - number_of_required_downfloats) / 2
    end
    alias_method :max_pairs, :maximum_number_of_pairs # FIDE nomenclature

    def can_finish_the_pairing?
      all_players_can_be_paired? && bye_can_be_selected?
    end

    def all_players_can_be_paired?
      number_of_possible_pairs == players.count / 2
    end

    def bye_can_be_selected?
      return true if players.count.even?

      players.select { |player| !player.had_bye? }.any? do |player|
        Bracket.for(players - [player]).all_players_can_be_paired?
      end
    end

    def number_of_required_downfloats
      @number_of_required_downfloats ||= if players.count.odd?
                                           1
                                         else
                                           0
                                         end
    end

    def number_of_moved_down_players
      @number_of_moved_down_players ||= moved_down_players.count
    end
    alias_method :m0, :number_of_moved_down_players # FIDE nomenclature


    def number_of_required_pairs
      raise "Implement in subclass"
    end

    def reduce_number_of_required_pairs
      raise "Implement in subclass"
    end

    def number_of_players_in_s1
      number_of_required_pairs
    end
    alias_method :n1, :number_of_players_in_s1 # FIDE nomenclature

    def number_of_required_mdps_from(players_in_the_previous_scoregroup)
      # TODO: write more tests and refactor.
      if players_in_the_previous_scoregroup.count.odd?
        if players.count.odd?
          (number_of_total_incompatibilities / 2) * 2 + 1
        else
          if number_of_total_incompatibilities == players.count
            (number_of_total_incompatibilities / 2) * 2 - 1
          else
            (number_of_total_incompatibilities / 2) * 2 + 1
          end
        end
      else
        if players.count.odd?
          (number_of_total_incompatibilities / 2) * 2
        else
          ((number_of_total_incompatibilities + 1) / 2) * 2
        end
      end
    end

    def s1
      return [] if number_of_players_in_s1 < 1
      players[0..number_of_players_in_s1-1].sort
    end

    def s2
      raise "Implement in subclass"
    end

    def s1_numbers
      s1.map(&:number)
    end

    def s2_numbers
      s2.map(&:number)
    end

    def exchange
      @players = next_exchange
    end

    def pairs
      return remainder_pairs if number_of_required_pairs.zero?

      until(current_exchange_pairs)
        if exchanger.limit_reached?
          reset_exchanger

          if quality.worst_possible?
            reset_quality
            return nil
          else
            quality.be_more_permissive
          end
        else
          exchange_until_s2_players_can_downfloat
        end
      end

      current_exchange_pairs
    end

    def leftovers
      pairs && definitive_unpaired_players.sort
    end

    def pairable_hypothetical_leftovers
      pairable_players & hypothetical_leftovers
    end

    def paired_players
      definitive_pairs.flat_map(&:players)
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map(&:numbers)
    end

    def leftover_numbers
      leftovers.map(&:number)
    end

    def mark_established_downfloats_as_impossible
      impossible_downfloats << definitive_unpaired_players.to_set
      clear_established_pairs
    end

    def forbidden_downfloats
      @forbidden_downfloats ||= Set.new
    end

    def mark_as_forbidden_downfloats(players)
      players.each { |player| forbidden_downfloats << player }
    end

    def reset_impossible_downfloats
      @impossible_downfloats = nil
    end

  private
    def exchanger
      raise "Implement in subclass"
    end

    def current_exchange_pairs
      return definitive_pairs if @definitive_pairs
      clear_pairs

      until(pairings_completed?)
        establish_pairs
        return nil if established_pairs.empty?

        if best_pairs_obtained?
          return @definitive_pairs = definitive_pairs
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
        if pair
          established_pairs << pair
        else
          return established_pairs
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
      opponents_for(player).map  { |opponent| Pair.new(player, opponent) }.each do |pair|
        return pair if is_possible?(pair)
      end

      nil
    end

    def opponents_for(player)
      player.compatible_players_in(s2) & still_unpaired_players
    end

    def is_possible?(pair)
      hypothetical_pairs = established_pairs + [pair]
      hypothetical_leftovers = (players - hypothetical_pairs.flat_map(&:players)).to_set
      !not_ideal_pairs.include?(hypothetical_pairs) &&
        !impossible_downfloats.include?(hypothetical_leftovers) &&
        (possible_non_s1_downfloats - pair.players).count >= number_of_required_downfloats
    end

    def pairable_players
      players.select { |player| player.compatible_players_in(players).any? }
    end

    def possible_non_s1_downfloats
      players[number_of_players_in_s1..-1] & still_unpaired_players &
        quality.possible_downfloats
    end

    def pairings_completed?
      established_pairs.count == number_of_required_pairs
    end

    def established_pairs
      @established_pairs ||= []
    end

    def clear_established_pairs
      @established_pairs = nil
      @definitive_pairs = nil
    end

    def not_ideal_pairs
      @not_ideal_pairs ||= Set.new
    end

    def impossible_downfloats
      @impossible_downfloats ||= Set.new
    end

    def mark_established_pairs_as_not_ideal
      not_ideal_pairs << established_pairs
      clear_established_pairs
    end

    def clear_pairs
      @not_ideal_pairs = nil
      clear_established_pairs
    end

    def next_exchange
      exchanger.next_exchange
    end

    def reset_exchanger
      @exchanger = nil
      players.sort!
    end

    def exchange_until_s2_players_can_downfloat
      begin
        exchange
      end until(exchanger.limit_reached? || possible_s2_downfloats.count >= number_of_required_downfloats)
    end

    def possible_s2_downfloats
      s2.reject { |player| forbidden_downfloats.include?(player) }
    end

    def still_unpaired_players
      players - established_pairs.flat_map(&:players)
    end

    def definitive_unpaired_players
      players - paired_players
    end

    def all_players_have_the_same_points?
      players.map(&:points).uniq.one?
    end

    def moved_down_players
      players.select { |player| player.points > points }
    end

    def number_of_opponent_incompatibilities
      number_of_opponent_incompatibilities_for(players)
    end

    def number_of_opponent_incompatibilities_for(players_to_pair)
      OpponentsIncompatibilities.new(players_to_pair, players).count
    end

    def number_of_compatible_pairs
      @number_of_compatible_pairs ||=
        (players.count - number_of_opponent_incompatibilities) / 2
    end

    def number_of_bye_incompatibilities
      if (leftovers.count > 0 && (leftovers - players.select(&:had_bye?)).empty?)
        if players.count.even?
          1
        else
          2
        end
      else
        0
      end
    end

    def number_of_total_incompatibilities
      number_of_opponent_incompatibilities + number_of_bye_incompatibilities
    end

    def best_possible_pairs?
      quality.ok?
    end

    def quality
      @quality ||= QualityCriterias.new(self)
    end

    def reset_quality
      @quality = nil
    end

    def remainder_pairs
      []
    end
  end
end
