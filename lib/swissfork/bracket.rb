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
    require "swissfork/completion"

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

    def number_of_moved_down_players
      @number_of_moved_down_players ||= moved_down_players.count
    end
    alias_method :m0, :number_of_moved_down_players # FIDE nomenclature


    def number_of_required_pairs
      raise "Implement in subclass"
    end

    def number_of_players_in_s1
      number_of_required_pairs
    end
    alias_method :n1, :number_of_players_in_s1 # FIDE nomenclature

    def number_of_required_mdps
      (0..players.count + 1).each do |number|
        additional_players = Array.new(number) do |index|
          Player.new(index + 10000) # Assuming there are less than 10000 players.
        end

        return number if Completion.new(players + additional_players).ok?
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
      return @definitive_pairs if instance_variable_defined?("@definitive_pairs")
      return [] if players.empty?
      return remainder_pairs if number_of_required_pairs.zero?
      return [] if number_of_possible_pairs < number_of_required_pairs

      until(@definitive_pairs = current_exchange_pairs)
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

      @definitive_pairs
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
      impossible_downfloats << definitive_unpaired_players
      clear_established_pairs
    end

    def forbidden_downfloats
      @forbidden_downfloats ||= Set.new
    end

    def forbidden_downfloats=(downfloats)
      @forbidden_downfloats = Set.new(downfloats.map { |players| players.to_set })
    end

    def mark_byes_as_forbidden_downfloats
      if players.count.odd?
        # HACK: we use arrays of 1 element, because that's the format
        # forbidden_downfloats expects.
        self.forbidden_downfloats = players.combination(1).select do |players|
          players.first.had_bye?
        end
      end
    end

    def reset_impossible_downfloats
      clear_pairs
      @impossible_downfloats = nil
    end

    def allowed_downfloats
      @allowed_downfloats ||= players.combination(number_of_required_downfloats).map { |downfloats| downfloats.to_set }.to_set - forbidden_downfloats
    end

  private
    def exchanger
      raise "Implement in subclass"
    end

    def current_exchange_pairs
      clear_pairs

      until(pairings_completed?)
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
      !not_ideal_pairs.include?(established_pairs + [pair]) &&
        !impossible_downfloats.include?(still_unpaired_players - pair.players) &&
        quality.can_downfloat?(unpaired_non_s1_players - [pair.s2_player])
    end

    def pairable_players
      players.select { |player| player.compatible_players_in(players).any? }
    end

    def unpaired_non_s1_players
      players[number_of_players_in_s1..-1] & still_unpaired_players
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

    def exchange_until_s2_players_can_downfloat
      begin
        exchange
      end until(exchanger.limit_reached? || quality.can_downfloat?(s2))
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
      @number_of_compatible_pairs ||= Completion.new(players).compatibilities
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
