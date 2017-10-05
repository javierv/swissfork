require "swissfork/bracket"

module Swissfork
  # Handles the pairing of a heterogeneous bracket.
  #
  # This class isn't supposed to be used directly; brackets
  # should be created using Bracket.for(players), which returns
  # either a homogeneous or a heterogeneous bracket.
  class HeterogeneousBracket < Bracket
    def initialize(players)
      super(players)
      @players = players_not_in_limbo.sort + limbo.sort
    end

    def pairs
      return remainder_pairs if number_of_required_pairs.zero?

      while(!current_exchange_pairs)
        if quality.worst_possible?
          if exchanger.limit_reached?
            limbo.push(s1.last)
            reset_exchanger
            reduce_number_of_moved_down_pairs
            return remainder_pairs if number_of_required_pairs.zero?
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

    def leftovers
      pairs && (still_unpaired_players - remainder_pairs.map(&:players).flatten).sort
    end

    def reduce_number_of_moved_down_pairs
      @set_maximum_number_of_moved_down_pairs ||= number_of_moved_down_possible_pairs
      @set_maximum_number_of_moved_down_pairs -= 1
    end

    def number_of_required_pairs
      @set_maximum_number_of_moved_down_pairs || number_of_moved_down_possible_pairs
    end

    def s2
      (players - (s1 + limbo)).sort
    end

  private
    def exchanger
      @exchanger ||= Exchanger.new(s1, limbo)
    end

    def best_pairs_obtained?
      pairings_completed? && (established_pairs + remainder_pairs).count == number_of_possible_pairs && best_possible_pairs?
    end

    def definitive_pairs
      established_pairs + remainder_pairs
    end

    def remainder_pairs
      HomogeneousBracket.new(still_unpaired_players - moved_down_players).pairs
    end

    def limbo
      @limbo ||= initial_limbo
    end

    def initial_limbo_count
      moved_down_players.count - number_of_moved_down_possible_pairs
    end

    def initial_limbo
      if initial_limbo_count > 0
        moved_down_players_sort_by_pairability[-1*initial_limbo_count..-1]
      else
        []
      end
    end

    def players_not_in_limbo
      players - limbo
    end

    def pairable_moved_down_players
      moved_down_players & pairable_players
    end

    def unpairable_moved_down_players
      moved_down_players & unpairable_players
    end

    def moved_down_players_sort_by_pairability
      pairable_moved_down_players.sort + unpairable_moved_down_players.sort
    end
  end
end
