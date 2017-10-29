require "simple_initialize"
require "swissfork/possible_pairs"

module Swissfork
  # Checks if a group of players can complete the pairing.
  #
  # In order to complete the pairing, they need to meet two
  # requirements:
  #
  # 1. All players must be paired meeting criteria C1 and C3.
  # 2. The player receiving the bye must meet criterion C2.
  class Completion
    initialize_with :players

    def ok?
      all_players_can_be_paired? && bye_can_be_selected?
    end

    def all_players_can_be_paired?
      (players.count - PossiblePairs.for(players).count * 2) < 2
    end

    def bye_can_be_selected?
      return true if players.count.even?

      players.select { |player| !player.had_bye? }.any? do |player|
        Completion.new(players - [player]).all_players_can_be_paired?
      end
    end

    def number_of_required_mdps
      (0..players.count + 1).each do |number|
        additional_players = Array.new(number) do |index|
          Player.new(index + players.map(&:number).max + 1)
        end

        return number if Completion.new(players + additional_players).ok?
      end
    end
  end
end
