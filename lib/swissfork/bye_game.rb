require "simple_initialize"

module Swissfork
  # Takes place when a player receives the
  # pairing-allocated bye
  class ByeGame
    initialize_with :player

    def opponent
      nil
    end

    def colour
      nil
    end

    def float
      :bye
    end

    def bye?
      true
    end

    def winner
      nil
    end

    def pair
      nil
    end

    def points_received
      1.0 # TODO: it depends on the tournament
    end

    def played?
      false
    end
  end
end
