require "simple_initialize"
require "swissfork/best_quality_calculator"
require "swissfork/moved_down_permit"
require "swissfork/moved_down_possible_pairs"

module Swissfork
  # Checks what's the best possible quality which can be obtained
  # pairing moved down players given the moved down players and
  # the resident players
  class MovedDownBestQualityCalculator < BestQualityCalculator
    initialize_with :moved_down_players, :resident_players

    def players
      moved_down_players + resident_players
    end

    def moved_down_possible_pairs
      @moved_down_possible_pairs ||=
        [moved_down_compatible_pairs, required_total_pairs,
         moved_down_pairs_after_downfloats].min
    end

    def moved_down_compatible_pairs
      @moved_down_compatible_pairs ||= MovedDownPossiblePairs.new(moved_down_players, resident_players).count
    end

    alias_method :allowed_homogeneous_downfloats, :allowed_downfloats

    def allowed_downfloats
      MovedDownPermit.new(moved_down_players, required_moved_down_downfloats, allowed_homogeneous_downfloats).allowed
    end

    def required_remainder_pairs
      required_total_pairs - moved_down_possible_pairs
    end

    # TODO: check conditions for heterogeneous brackets.
    def colour_violations
      colour_incompatibilities.violations
    end

    # TODO: check conditions for heterogeneous brackets.
    def incompatible_colours?(player, opponent)
      false
    end

  private
    def minimum_number_of_moved_down_downfloats
      allowed_homogeneous_downfloats.map do |downfloats|
        (downfloats - resident_players).count
      end.min.to_i
    end

    def required_total_pairs
      possible_pairs
    end

    def required_moved_down_downfloats
      moved_down_players.count - moved_down_possible_pairs
    end

    def moved_down_pairs_after_downfloats
      moved_down_players.count - minimum_number_of_moved_down_downfloats
    end
  end
end
