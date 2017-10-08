require "swissfork/bracket"

module Swissfork
  # Handles the pairing of a heterogeneous bracket.
  #
  # This class isn't supposed to be used directly; brackets
  # should be created using Bracket.for(players), which returns
  # either a homogeneous or a heterogeneous bracket.
  class HeterogeneousBracket < Bracket
    def pairs
      return remainder_pairs if number_of_required_pairs.zero?

      until(current_exchange_pairs)
        if quality.worst_possible?
          reset_quality

          if exchanger.limit_reached?
            reset_exchanger
            reduce_number_of_moved_down_pairs
            return remainder_pairs if number_of_required_pairs.zero?
          else
            exchange_until_s2_players_can_downfloat
          end
        else
          quality.be_more_permissive
          restart_pairs
        end
      end

      current_exchange_pairs
    end

    def leftovers
      pairs && (still_unpaired_players - remainder_pairs.flat_map(&:players)).sort
    end

    def number_of_required_pairs
      @set_maximum_number_of_moved_down_pairs || number_of_moved_down_possible_pairs
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
      super && (established_pairs + remainder_pairs).count == number_of_possible_pairs
    end

    def clear_established_pairs
      @remainder_pairs = nil
      super
    end

    def definitive_pairs
      super + remainder_pairs
    end

    def remainder_pairs
      @remainder_pairs ||= HomogeneousBracket.new(still_unpaired_players - moved_down_players).pairs
    end

    def initial_number_of_players_in_limbo
      @initial_number_of_players_in_limbo ||=
        moved_down_players.count - number_of_required_pairs
    end

    def number_of_players_in_limbo
      @set_number_of_players_in_limbo || initial_number_of_players_in_limbo
    end

    def reduce_number_of_moved_down_pairs
      @set_number_of_players_in_limbo = number_of_players_in_limbo + 1
      @set_maximum_number_of_moved_down_pairs = number_of_required_pairs - 1
    end
  end
end
