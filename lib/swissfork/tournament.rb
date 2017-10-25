require "simple_initialize"
require "swissfork/round"
require "swissfork/player"
require "swissfork/unpaired_game"

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

    def pairs
      current_round.pairs
    end

    def pair_numbers
      # Hack because the helper method returns wrong colours during the
      # first round.
      pairs.map { |pair| pair.players.map(&:number) }
    end

    def start
      assign_player_numbers
    end

    def start_round
      # TODO: raise exception if there are no more rounds allowed and if the
      # current round isn't finished.
      assign_player_numbers unless players
      rounds << Round.new(players - non_paired_players).tap { |round| round.number = rounds.count + 1 }
    end

    def finish_round(results)
      current_round.results = results
      non_paired_players.each { |player| player.add_game(UnpairedGame.new(player)) }
      @non_paired_players = nil
    end

    def assign_player_numbers
      @players = inscriptions.sort.map.with_index do |inscription, index|
        Player.new(index + 1).tap do |player|
          player.inscription = inscription
        end
      end
    end

    def non_paired_numbers=(numbers)
      @non_paired_players = numbers.map { |number| players[number - 1] }
    end

  private
    def non_paired_players
      @non_paired_players ||= []
    end

    def inscriptions
      @inscriptions ||= []
    end
  end
end
