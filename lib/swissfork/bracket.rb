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
    require "swissfork/quality_criteria"
    require "swissfork/heterogeneous_bracket"
    require "swissfork/homogeneous_bracket"
    require "swissfork/possible_pairs"
    require "swissfork/colour_incompatibilities"
    require "swissfork/ok_permit"

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
      [number_of_pairs_after_downfloats, number_of_compatible_pairs].min
    end
    alias_method :max_pairs, :number_of_possible_pairs # FIDE nomenclature

    def minimum_colour_violations
      colour_incompatibilities.violations
    end
    alias_method :x1, :minimum_colour_violations # Old FIDE nomenclature

    def minimum_strong_colour_violations
      colour_incompatibilities.strong_violations
    end
    alias_method :z1, :minimum_strong_colour_violations # Old FIDE nomenclature

    def number_of_pairs_after_downfloats
      (players.count - number_of_required_downfloats) / 2
    end

    def number_of_required_downfloats
      @number_of_required_downfloats ||=
        players.count - number_of_compatible_pairs * 2
    end

    def number_of_required_downfloats=(number)
      @number_of_required_downfloats = [number, players.count - number_of_possible_pairs * 2].max
    end

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
      return @definitive_pairs if instance_variable_defined?("@definitive_pairs")
      @definitive_pairs = calculate_pairs
    end

    def leftovers
      pairs && definitive_unpaired_players.sort
    end

    # Here we consider the leftovers after we've completed
    # the pairing but we need to check for its quality.
    def pairable_provisional_leftovers
      pairable_players & provisional_leftovers
    end

    def provisional_pairs
      established_pairs
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

    def downfloat_permit
      @downfloat_permit ||= OkPermit.new(players, number_of_required_downfloats)
    end

    attr_writer :downfloat_permit

    def allowed_downfloats
      @allowed_downfloats ||= allowed_homogeneous_downfloats
    end

    def all_downfloats_are_impossible?
      !number_of_required_downfloats.zero? &&
        (allowed_downfloats - impossible_downfloats).empty?
    end

    def allowed_homogeneous_downfloats
      downfloat_permit.allowed
    end

    def reset_impossible_downfloats
      clear_pairs
      reset_exchanger
      @impossible_downfloats = nil
    end

    def failing_criteria
      @failing_criteria ||= []
    end

    def reset_failing_criteria
      @failing_criteria = nil
    end

  private
    attr_reader :definitive_pairs

    def exchanger
      raise "Implement in subclass"
    end

    def calculate_pairs
      return [] if players.empty?
      return remainder_pairs if number_of_required_pairs.zero?
      return [] if number_of_possible_pairs < number_of_required_pairs
      return nil if all_downfloats_are_impossible?

      until(pairs = current_exchange_pairs)
        if exchanger.limit_reached?
          reset_exchanger
          quality.be_more_permissive
        else
          exchange_until_non_s1_players_can_downfloat
        end
      end

      pairs
    end

    def current_exchange_pairs
      clear_pairs

      until(best_pairs_obtained?)
        mark_established_pairs_as_not_ideal
        establish_pairs
        return nil if established_pairs.empty?
      end

      provisional_pairs
    end

    def establish_pairs
      s1.each do |player|
        pair = pair_for(player)
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

    def pair_for(player)
      pairs_for(player).each { |pair| return pair if is_possible?(pair) }
      nil
    end

    def pairs_for(player)
      opponents_for(player).map  { |opponent| Pair.new(player, opponent) }
    end

    def opponents_for(player)
      player.compatible_players_in(s2) & still_unpaired_players
    end

    def is_possible?(pair)
      !not_ideal_pairs.include?(established_pairs + [pair]) &&
        !impossible_downfloats.include?((still_unpaired_players - pair.players).to_set) &&
        quality.can_downfloat?(unpaired_non_s1_players - [pair.s2_player])
    end

    def pairable_players
      players.select { |player| player.compatible_players_in(players).any? }
    end

    def unpaired_non_s1_players
      non_s1_players & still_unpaired_players
    end

    def non_s1_players
      players[number_of_players_in_s1..-1]
    end

    def pairings_completed?
      established_pairs.count == number_of_required_pairs
    end

    def established_pairs
      @established_pairs ||= []
    end

    def clear_established_pairs
      @established_pairs = nil

      if instance_variable_defined?("@definitive_pairs")
        remove_instance_variable("@definitive_pairs")
      end
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

    def exchange_until_non_s1_players_can_downfloat
      begin
        exchange
      end until(exchanger.limit_reached? || quality.can_downfloat?(non_s1_players))
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

    def number_of_compatible_pairs
      @number_of_compatible_pairs ||= PossiblePairs.new(players).count
    end

    def best_possible_pairs?
      if quality.ok?
        true
      else
        failing_criteria << quality.failing_criterion
        false
      end
    end

    def quality
      @quality ||= QualityCriteria.new(self)
    end

    def colour_incompatibilities
      ColourIncompatibilities.new(players, number_of_possible_pairs)
    end

    def remainder_pairs
      []
    end
  end
end
