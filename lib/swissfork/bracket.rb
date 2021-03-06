require "set"
require "swissfork/pair"
require "swissfork/exchanger"
require "swissfork/quality_criteria"
require "swissfork/best_quality_calculator"
require "swissfork/possible_pairs"
require "swissfork/quality_checker"

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
    require "swissfork/heterogeneous_bracket"
    require "swissfork/homogeneous_bracket"

    include Comparable
    attr_reader :players

    def self.for(players)
      if players.map(&:points).uniq.one?
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

    def number_of_possible_pairs
      quality_calculator.possible_pairs
    end
    alias_method :max_pairs, :number_of_possible_pairs # FIDE nomenclature

    def number_of_required_downfloats
      quality_calculator.required_downfloats
    end

    def number_of_required_downfloats=(number)
      quality_calculator.required_downfloats = number
    end

    def number_of_required_pairs
      raise "Implement in subclass"
    end

    def number_of_players_in_s1
      number_of_required_pairs
    end
    alias_method :n1, :number_of_players_in_s1 # FIDE nomenclature

    def s1
      players.first(number_of_players_in_s1).sort
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
    # the pairing but before checking its quality.
    def provisional_leftovers
      raise "Implement in subclass"
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
      clear_definitive_pairs
    end

    def downfloat_permit=(permit)
      quality_calculator.downfloat_permit = permit
    end

    def allowed_downfloats
      @allowed_downfloats ||= quality_calculator.allowed_downfloats
    end

    def all_downfloats_are_impossible?
      !number_of_required_downfloats.zero? &&
        (allowed_downfloats - impossible_downfloats).empty?
    end

    def reset_impossible_downfloats
      clear_definitive_pairs
      reset_exchanger
      @impossible_downfloats = nil
    end

    def quality_calculator
      @quality_calculator ||= BestQualityCalculator.new(players)
    end

    private

      attr_reader :definitive_pairs

      def exchanger
        raise "Implement in subclass"
      end

      def calculate_pairs
        return [] if players.empty?
        return remainder_pairs if number_of_required_pairs.zero?
        return nil if all_downfloats_are_impossible?

        until (pairs = current_exchange_pairs)
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
        clear_not_ideal_pairs
        clear_established_pairs

        loop do
          establish_pairs

          return nil if established_pairs.empty?
          return provisional_pairs if best_pairs_obtained?

          not_ideal_pairs << established_pairs
          clear_established_pairs
        end
      end

      def establish_pairs
        index = 0
        until pairings_completed? || index < 0
          pair = pair_for(players[index])
          if pair
            established_pairs << pair
            index += 1
          else
            not_ideal_pairs << established_pairs.dup
            established_pairs.pop
            index -= 1
          end
        end
      end

      def best_pairs_obtained?
        quality.ok?
      end

      def pair_for(player)
        pairs_for(player).find { |pair| possible?(pair) }
      end

      def pairs_for(player)
        opponents_for(player).map { |opponent| Pair.new(player, opponent) }
      end

      def opponents_for(player)
        player.compatible_opponents_in(s2) & still_unpaired_players
      end

      def possible?(pair)
        hypothetical_pairs = established_pairs + [pair]
        hypothetical_leftovers = still_unpaired_players - pair.players

        !not_ideal_pairs.include?(hypothetical_pairs) &&
          !impossible_downfloats.include?(hypothetical_leftovers.to_set) &&
          number_of_required_pairs <= hypothetical_pairs.size + PossiblePairs.new(hypothetical_leftovers).count &&
          QualityChecker.new(hypothetical_pairs, hypothetical_leftovers & non_s1_players, quality_calculator).colours_and_downfloats_are_ok?
      end

      def non_s1_players
        players[number_of_players_in_s1..-1]
      end

      def pairings_completed?
        established_pairs.size == number_of_required_pairs
      end

      def established_pairs
        @established_pairs ||= []
      end

      def clear_established_pairs
        @established_pairs = nil
      end

      def not_ideal_pairs
        @not_ideal_pairs ||= Set.new
      end

      def clear_not_ideal_pairs
        @not_ideal_pairs = nil
      end

      def impossible_downfloats
        @impossible_downfloats ||= Set.new
      end

      def clear_definitive_pairs
        if instance_variable_defined?("@definitive_pairs")
          remove_instance_variable("@definitive_pairs")
        end
      end

      def next_exchange
        exchanger.next_exchange
      end

      def reset_exchanger
        @exchanger = nil
        players.sort!
      end

      def exchange_until_non_s1_players_can_downfloat
        loop do
          exchange
          break if exchanger.limit_reached? || non_s1_players_can_downfloat?
        end
      end

      def non_s1_players_can_downfloat?
        QualityChecker.new([], non_s1_players, quality_calculator).can_downfloat?
      end

      def still_unpaired_players
        players - established_pairs.flat_map(&:players)
      end

      def definitive_unpaired_players
        players - paired_players
      end

      def moved_down_players
        players.select { |player| player.points > points }
      end

      def quality
        @quality ||= QualityCriteria.new(self)
      end

      def remainder_pairs
        []
      end
  end
end
