require "simple_initialize"
require "swissfork/possible_pairs"
require "swissfork/colour_incompatibilities"
require "swissfork/ok_permit"

module Swissfork
  # Checks what's the best possible quality which can be obtained
  # given some players and the number of players who are going to
  # downfloat.
  class BestQualityCalculator
    initialize_with :players

    def possible_pairs
      [pairs_after_downfloats, compatible_pairs].min
    end

    def required_downfloats
      @required_downfloats ||= players.count - compatible_pairs * 2
    end

    # Sets the required number of downfloats in order to fulfil criterion C.4
    def required_downfloats=(number)
      @required_downfloats = [number, players.count - possible_pairs * 2].max
    end

    def pairs_after_downfloats
      (players.count - required_downfloats) / 2
    end

    def downfloat_permit
      @downfloat_permit ||= OkPermit.new(players, required_downfloats)
    end

    attr_writer :downfloat_permit

    def allowed_downfloats
      downfloat_permit.allowed
    end

    # Criterion C.10
    def colour_violations
      colour_incompatibilities.violations
    end
    alias_method :x1, :colour_violations # Old FIDE nomenclature

    # Criterion C.11
    def strong_colour_violations
      colour_incompatibilities.strong_violations
    end
    alias_method :z1, :strong_colour_violations # Old FIDE nomenclature

    def no_preference_violations_for(colour)
      colour_incompatibilities.no_preference_violations_for(colour)
    end

    def colour_violations_for(colour)
      colour_incompatibilities.violations_for(colour)
    end

    def allowed_failures
      @allowed_failures ||= {
        colour_preference_violation?: colour_violations,
        white_colour_preference_violation?: colour_violations_for(:white),
        black_colour_preference_violation?: colour_violations_for(:black),
        white_preference_playing_players_with_no_preference?: no_preference_violations_for(:white),
        black_preference_playing_players_with_no_preference?: no_preference_violations_for(:black),
        strong_colour_preference_violation?: strong_colour_violations,
        same_downfloats_as_previous_round?: same_downfloats_as_previous_round_violations,
      }.tap { |failures| failures.default = 0 }
    end

    def failing_criteria
      @failing_criteria ||= []
    end

    def reset_failing_criteria
      @failing_criteria = nil
    end

  private
    # Criterion C.5
    def compatible_pairs
      @compatible_pairs ||= PossiblePairs.new(players).count
    end

    def colour_incompatibilities
      @colour_incompatibilities ||= ColourIncompatibilities.new(players, possible_pairs)
    end

    def resident_players
      players
    end

    # TODO: add tests.
    def same_downfloats_as_previous_round_violations
      [required_downfloats - resident_players.reject(&:descended_in_the_previous_round?).count, 0].max
    end

    def minoritary_preference
      colour_incompatibilities.minoritary_preference
    end
  end
end
