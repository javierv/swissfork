require "simple_initialize"

module Swissfork
  class Player
    include Comparable

    initialize_with :number
    attr_reader :opponents

    def opponents
      @opponents ||= []
    end

    def <=>(other_player)
      if points == other_player.points
        number <=> other_player.number
      else
        other_player.points <=> points
      end
    end

    def compatible_with?(player)
      !opponents.include?(player)
    end

    # FIXME: Currently a stub for tests.
    def points
      0
    end
  end
end
