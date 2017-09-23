require "simple_initialize"

module Swissfork
  # This class isn't supposed to be used by other classes, with the
  # exception of the Bracket class.
  class HeterogeneousBracket < Bracket
    def pairs
      reset_pairs

      while(!pairings_completed?)
        establish_pairs
        return nil if established_pairs.empty?

        if pairings_completed? && remainder_pairs.any? && best_possible_pairs?
          return established_pairs + remainder_pairs
        else
          mark_established_pairs_as_impossible
        end
      end
    end

  private
    def remainder_pairs
      Bracket.new(unpaired_players_after(established_pairs)).pairs
    end
  end
end
