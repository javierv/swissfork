require "swissfork/exchanger"

module Swissfork
  # Handles exchanges of players between S1 and Limbo in
  # heterogeneous brackets, as described in FIDE system,
  # sections D.3.
  class LimboExchanger < Exchanger
    alias_method :limbo, :s2

    private

      def maximum_number_of_players_in_a_exchange
        [s1.size, limbo.size].min
      end
  end
end
