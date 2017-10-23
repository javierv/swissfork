require "simple_initialize"
require "swissfork/round"
require "swissfork/player"

module Swissfork
  class Tournament
    initialize_with :number_of_rounds
    attr_reader :players

    def name
      "Championship" # TODO
    end

    def add_inscription(inscription)
      inscriptions.push(inscription)
    end

    def rounds
      @rounds ||= []
    end

    def current_round
      rounds.last
    end

    def start_round
      # TODO: raise exception if there are no more rounds allowed and if the
      # current round isn't finished.
      assign_player_numbers if rounds.empty?
      rounds << Round.new(players).tap { |round| round.number = rounds.count + 1 }
    end

    def finish_round(results)
      current_round.results = results
    end

    def assign_player_numbers
      @players = inscriptions.sort.map.with_index do |inscription, index|
        Player.new(index + 1).tap do |player|
          player.inscription = inscription
        end
      end
    end

  private
    def inscriptions
      @inscriptions ||= []
    end
  end
end
