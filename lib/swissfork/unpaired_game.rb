require "simple_initialize"

module Swissfork
  # Takes place when a player asks not to be paired
  # before a round begins
  class UnpairedGame
    initialize_with :player

    def opponent
      nil
    end

    def colour
      nil
    end

    # Defined in A.4.b.
    def float
      :down
    end

    def bye?
      false
    end

    def winner
      nil
    end

    def pair
      nil
    end

    def points_received
      0.5 # TODO: it depends on the tournament
    end

    def played?
      false
    end
  end
end
