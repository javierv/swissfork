require "simple_initialize"

module Swissfork
  # This class isn't supposed to be used by other classes, with the
  # exception of the Bracket class.
  class HeterogeneousBracket < Bracket
    def pairs
      current_exchange_pairs
    end

  private
    def definitive_pairs_obtained?
      pairings_completed? && remainder_pairs.any? && best_possible_pairs?
    end

    def definitive_pairs
      established_pairs + remainder_pairs
    end

    def remainder_pairs
      Bracket.new(unpaired_players_after(established_pairs)).pairs
    end
  end
end
