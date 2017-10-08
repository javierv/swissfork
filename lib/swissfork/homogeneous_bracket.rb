require "swissfork/bracket"

module Swissfork
  # Handles the pairing of a homogeneous bracket.
  #
  # This class isn't supposed to be used directly; brackets
  # should be created using Bracket.for(players), which returns
  # either a homogeneous or a heterogeneous bracket.
  class HomogeneousBracket < Bracket
    def number_of_required_pairs
      @set_number_of_required_pairs || number_of_possible_pairs
    end

    def pairs
      return [] if number_of_required_pairs.zero?

      until(current_exchange_pairs)
        if exchanger.limit_reached?
          reset_exchanger

          if quality.worst_possible?
            reduce_number_of_required_pairs
            reset_quality
            return [] if number_of_required_pairs.zero?
          else
            quality.be_more_permissive
          end
        else
          exchange_until_s2_players_can_downfloat
        end
      end

      current_exchange_pairs
    end

  private
    def exchanger
      @exchanger ||= Exchanger.new(s1, s2)
    end

    def reduce_number_of_required_pairs
      @set_number_of_required_pairs = number_of_required_pairs - 1
    end
  end
end
