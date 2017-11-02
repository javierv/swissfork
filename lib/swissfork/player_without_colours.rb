require "swissfork/player"

module Swissfork
  # This class is used in tournaments where colour
  # preferences are irrelevant, like non-chess
  # tournaments.
  class PlayerWithoutColours < Player
    def colours
      []
    end

    def prefers_white_by_default?
      true
    end
  end
end
