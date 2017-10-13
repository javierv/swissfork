require "swissfork/bracket"

module Swissfork
  # Handles the pairing of a heterogeneous bracket.
  #
  # This class isn't supposed to be used directly; brackets
  # should be created using Bracket.for(players), which returns
  # either a homogeneous or a heterogeneous bracket.
  class HeterogeneousBracket < Bracket
    def number_of_moved_down_possible_pairs
      @number_of_moved_down_possible_pairs ||=
        moved_down_players.count - number_of_moved_down_opponent_incompatibilities
    end
    alias_method :m1, :number_of_moved_down_possible_pairs # FIDE nomenclature

    # This definition allows heterogeneous brackets to use the same
    # pairing algorithm as homogeneous brackets do.
    def number_of_required_pairs
      number_of_required_moved_down_pairs
    end

    # Criteria C.5 and C.6. Assuming we've got 4 MDPs and 6 resident players,
    # the combinations we try will be, in descendent order:
    # 4 MDP pairs + 1 remainder pair (5 pairs, which is the maximum)
    # 4 MDPs + 0 remainder
    # 3 MDPs + 1 remainder
    # 2 MDPs + 2 remainder
    # 3 MDPs + 0 remainder (for 1 MDP + 3 remainder we'd need 7 resident players)
    # 2 MDPs + 1 remainder
    # ...
    def reduce_number_of_required_pairs
      if can_reduce_moved_down_pairs?
        reduce_number_of_moved_down_pairs
      else
        reduce_number_of_total_pairs
        reset_number_of_moved_down_pairs
      end
    end

    def number_of_required_total_pairs
      @number_of_required_total_pairs ||= number_of_possible_pairs
    end

    def number_of_required_moved_down_pairs
      @number_of_required_moved_down_pairs ||=
        [number_of_moved_down_possible_pairs, number_of_required_total_pairs].min
    end

    def number_of_required_remainder_pairs
      number_of_required_total_pairs - number_of_required_moved_down_pairs
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

  private
    def exchanger
      @exchanger ||= Exchanger.new(s1, limbo)
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

    def definitive_pairs
      super + remainder_pairs.to_a
    end

    def remainder_pairs
      remainder_bracket.number_of_required_pairs = number_of_required_remainder_pairs

      while(impossible_downfloats.include?(hypothetical_leftovers.to_set))
        remainder_bracket.mark_established_downfloats_as_impossible
      end

      remainder_bracket.pairs
    end

    def remainder_bracket
      @remainder_bracket ||= HomogeneousBracket.new(remainder_players)
    end

    def remainder_players
      still_unpaired_players - moved_down_players
    end

    def hypothetical_leftovers
      players - (established_pairs + remainder_bracket.pairs.to_a).flat_map(&:players)
    end

    def number_of_players_in_limbo
      moved_down_players.count - number_of_required_moved_down_pairs
    end

    def number_of_moved_down_opponent_incompatibilities
      number_of_opponent_incompatibilities_for(moved_down_players)
    end

    def can_reduce_moved_down_pairs?
      number_of_required_moved_down_pairs > 0 && can_increase_remainder_pairs?
    end

    def can_increase_remainder_pairs?
      (number_of_required_moved_down_pairs - 1) + (number_of_required_remainder_pairs + 1) * 2 <= resident_players.count
    end

    def resident_players
      players - moved_down_players
    end

    def reduce_number_of_total_pairs
      @number_of_required_total_pairs = number_of_required_total_pairs - 1
    end

    def reduce_number_of_moved_down_pairs
      @number_of_required_moved_down_pairs = number_of_required_moved_down_pairs - 1
    end

    def reset_number_of_moved_down_pairs
      @number_of_required_moved_down_pairs = nil
    end
  end
end
