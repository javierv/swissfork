require "swissfork/bracket"

module Swissfork
  class HeterogeneousBracket < Bracket
    require "swissfork/remainder"

    def leftovers
      pairs && (still_unpaired_players - remainder_pairs.map(&:players).flatten)
    end

    def number_of_players_in_s1
      number_of_pairable_moved_down_players
    end

    def number_of_required_pairs
      number_of_pairable_moved_down_players
    end

    def best_pairs_obtained?
      pairings_completed? && remainder_pairs.any? && best_possible_pairs?
    end

    def definitive_pairs
      established_pairs + remainder_pairs
    end

    def pairs
      current_exchange_pairs
    end

    def remainder_pairs
      Remainder.new(still_unpaired_players).pairs
    end
  end
end
