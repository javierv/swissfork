require "simple_initialize"

module Swissfork
  # This class isn't supposed to be used by other classes, with the
  # exception of the Bracket class.
  class HeterogeneousBracket < Bracket
    def pairs
      reset_pairs

      while(!pairings_completed?)
        establish_pairs

        if pairings_completed?
          if remainder_pairs.any? && best_possible_pairs?
            return established_pairs + remainder_pairs
          else
            mark_established_pairs_as_impossible
          end
        else
          return nil if established_pairs.empty?
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
