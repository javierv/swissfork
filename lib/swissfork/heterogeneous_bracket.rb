require "swissfork/bracket"

module Swissfork
  # Handles the pairing of a heterogeneous bracket.
  #
  # This class isn't supposed to be used directly; brackets
  # should be created using Bracket.for(players), which returns
  # either a homogeneous or a heterogeneous bracket.
  class HeterogeneousBracket < Bracket
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
      pairings_completed? && (established_pairs + remainder_pairs).count == number_of_possible_pairs && best_possible_pairs?
    end

    def definitive_pairs
      established_pairs + remainder_pairs
    end

    def pairs
      while(!current_exchange_pairs)
        if quality.worst_possible?
          if exchanger.limit_reached?
            return []
          else
            exchange
            restart_pairs
          end
        else
          quality.be_more_permissive
          restart_pairs
        end
      end

      current_exchange_pairs
    end

    def remainder_pairs
      HomogeneousBracket.new(still_unpaired_players).pairs
    end
  end
end
