require "swissfork/bracket"
require "swissfork/limbo_exchanger"
require "swissfork/moved_down_permit"

module Swissfork
  # Handles the pairing of a heterogeneous bracket.
  #
  # This class isn't supposed to be used directly; brackets
  # should be created using Bracket.for(players), which returns
  # either a homogeneous or a heterogeneous bracket.
  class HeterogeneousBracket < Bracket
    def number_of_moved_down_players
      @number_of_moved_down_players ||= moved_down_players.count
    end
    alias_method :m0, :number_of_moved_down_players # FIDE nomenclature

    # This definition allows heterogeneous brackets to use the same
    # pairing algorithm as homogeneous brackets do.
    def number_of_required_pairs
      number_of_moved_down_possible_pairs
    end

    def number_of_moved_down_possible_pairs
      @number_of_moved_down_possible_pairs ||=
        [number_of_moved_down_compatible_pairs, number_of_required_total_pairs,
         number_of_moved_down_pairs_after_downfloats].min
    end
    alias_method :m1, :number_of_moved_down_possible_pairs # FIDE nomenclature

    def number_of_moved_down_compatible_pairs
      @number_of_moved_down_compatible_pairs ||= PossiblePairs.new(moved_down_players, resident_players).count
    end

    def number_of_required_total_pairs
      @number_of_required_total_pairs ||= number_of_possible_pairs
    end

    def number_of_moved_down_pairs_after_downfloats
      number_of_moved_down_players - minimum_number_of_moved_down_downfloats
    end

    def number_of_required_moved_down_downfloats
      number_of_moved_down_players - number_of_moved_down_possible_pairs
    end

    def minimum_number_of_moved_down_downfloats
      allowed_homogeneous_downfloats.map do |downfloats|
        (downfloats - resident_players).count
      end.min.to_i
    end

    def allowed_downfloats
      @allowed_downfloats ||= MovedDownPermit.new(moved_down_players, number_of_required_moved_down_downfloats, allowed_homogeneous_downfloats).allowed
    end

    def number_of_required_remainder_pairs
      number_of_required_total_pairs - number_of_moved_down_possible_pairs
    end

    def s2
      players[number_of_players_in_s1+number_of_players_in_limbo..-1]
    end

    def limbo
      if number_of_players_in_limbo.zero?
        []
      else
        (players - s1)[0..number_of_players_in_limbo-1].sort
      end
    end

    def limbo_numbers
      limbo.map(&:number)
    end

    def provisional_pairs
      super + remainder_pairs.to_a
    end

    def resident_players
      players - moved_down_players
    end

  private
    def exchanger
      @exchanger ||= LimboExchanger.new(s1, limbo)
    end

    def next_exchange
      super + s2
    end

    def pairings_completed?
      super && remainder_pairs.to_a.count == number_of_required_remainder_pairs
    end

    def clear_established_pairs
      @remainder_bracket = nil
      super
    end

    def remainder_pairs
      remainder_bracket.number_of_required_pairs = number_of_required_remainder_pairs

      while(impossible_downfloats.include?(unpaired_players_after_remainder.to_set))
        remainder_bracket.mark_established_downfloats_as_impossible
      end

      remainder_bracket.pairs
    end

    def unpaired_players_after_remainder
      still_unpaired_players - remainder_bracket.pairs.to_a.flat_map(&:players)
    end

    def remainder_bracket
      @remainder_bracket ||= HomogeneousBracket.new(remainder_players)
    end

    def remainder_players
      still_unpaired_players - moved_down_players
    end

    def provisional_leftovers
      still_unpaired_players & moved_down_players
    end

    def number_of_players_in_limbo
      number_of_moved_down_players - number_of_moved_down_possible_pairs
    end
  end
end
