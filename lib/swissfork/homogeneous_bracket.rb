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
      until(current_exchange_pairs)
        if exchanger.limit_reached?
          if quality.worst_possible?
            return []
          else
            quality.be_more_permissive
            reset_exchanger
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
  end
end
