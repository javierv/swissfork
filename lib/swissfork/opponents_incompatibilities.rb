require "simple_initialize"

module Swissfork
  # Given a list of players to pair and possible opponents,
  # it calculates if some players remain unpaired.
  #
  # For example, if we've got players 1, 2, 3, 4, and 2 has
  # played against 3 and 4, in theory all players have possible
  # opponents and can be paired. However, if we pair number 2,
  # numbers 3 and 4 will remain unpaired, because their only
  # possible opponent (number 1) can't play against more than one
  # player.
  class OpponentsIncompatibilities
    initialize_with :players, :opponents

    def count
      list.uniq.reduce(0) do |incompatibilities, opponents|
        if list.count(opponents) > opponents.count
          incompatibilities + list.count(opponents) - opponents.count
        else
          incompatibilities
        end
      end
    end

  private
    def list
      @list ||= players.map { |player| player.compatible_players_in(opponents) }
    end
  end
end
