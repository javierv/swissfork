module Swissfork
  # Takes place when a player asks not to be paired
  # before a round begins
  class UnpairedGame
    def initialize(player, points: default_points_received)
      @player = player
      @points_received = points.to_f
    end
    attr_reader :points_received

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

    def played?
      false
    end

    private

      def default_points_received
        0.5
      end
  end
end
