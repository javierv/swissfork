require "swissfork/unpaired_game"

module Swissfork
  # Takes place when a player receives the
  # pairing-allocated bye
  class ByeGame < UnpairedGame
    def float
      :bye
    end

    def bye?
      true
    end

    private

      def default_points_received
        1.0 # TODO: it depends on the tournament
      end
  end
end
