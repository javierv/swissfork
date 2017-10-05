require "swissfork/bracket"

module Swissfork
  # Handles the pairing of a homogeneous bracket.
  #
  # This class isn't supposed to be used directly; brackets
  # should be created using Bracket.for(players), which returns
  # either a homogeneous or a heterogeneous bracket.
  class HomogeneousBracket < Bracket
    def leftovers
      pairs && still_unpaired_players.sort
    end

    def number_of_required_pairs
      number_of_possible_pairs
    end

    def pairs
      while(!current_exchange_pairs)
        if exchanger.limit_reached?
          if quality.worst_possible?
            return []
          else
            quality.be_more_permissive
            restart_pairs
            reset_exchanger
          end
        else
          exchange
          restart_pairs
        end
      end

      current_exchange_pairs
    end

  private
    def best_pairs_obtained?
      pairings_completed? && best_possible_pairs?
    end

    def definitive_pairs
      established_pairs
    end
  end
end
