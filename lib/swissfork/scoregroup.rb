require "simple_initialize"

module Swissfork
  # Holds information about a bracket and the rest of the
  # brackets we need to pair.
  #
  # Sometimes a bracket needs to know about other brackets;
  # for example, in criterias C.4 (penultimate bracket) and
  # C.7 (maximize pairs in the next bracket).
  class Scoregroup
    require "swissfork/penultimate_bracket_handler"

    initialize_with :bracket, :brackets

    def pairs
      if bracket.heterogeneous? && !last?
        move_unpairable_moved_down_players_to_limbo
      end

      if penultimate?
        if next_bracket_pairing_is_ok?
          bracket.pairs
        else
          handler.move_players_to_allow_last_bracket_pairs && bracket.pairs
        end
      else
        bracket.pairs
      end
    end

    def points
      bracket.points
    end

    def leftovers
      limbo + bracket.leftovers.to_a
    end

    def players
      bracket.players
    end

    def move_leftovers_to_next_bracket
      next_bracket.add_players(leftovers)
      bracket.remove_players(leftovers)
    end

    def mark_established_pairs_as_impossible
      bracket.mark_established_pairs_as_impossible
    end

    def last?
      bracket == brackets.last
    end

    def pair_numbers
      pairs.map(&:numbers)
    end

  private
    def move_unpairable_moved_down_players_to_limbo
      limbo.push(*unpairable_moved_down_players)
      bracket.remove_players(unpairable_moved_down_players)
    end

    def unpairable_moved_down_players
      bracket.unpairable_moved_down_players
    end

    def next_bracket
      brackets[brackets.index(bracket) + 1]
    end

    def penultimate?
      brackets.count > 1 && bracket == brackets[-2]
    end

    def handler
      PenultimateBracketHandler.new(bracket, next_bracket)
    end

    def hypothetical_next_pairs
      Bracket.for(leftovers + next_bracket.players).pairs
    end

    def next_bracket_pairing_is_ok?
      hypothetical_next_pairs && !hypothetical_next_pairs.empty?
    end

    def limbo
      @limbo ||= []
    end
  end
end
