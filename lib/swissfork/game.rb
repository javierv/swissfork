require "simple_initialize"

module Swissfork
  # Contains the game data associated to a player.
  #
  # The information it contains is similar to Pair, but
  # Pair shows information from an objective point of view,
  # and Game shows information from the player point of view.
  class Game
    initialize_with :player, :pair

    def opponent
      @opponent ||= (players - [player]).first
    end

    def colour
      if played?
        if player == white
          :white
        else
          :black
        end
      end
    end

    def float
      if played?
        case pair.points_before_playing[player.id] <=> pair.points_before_playing[opponent.id]
        when -1 then :up
        when 1 then :down
        end
      elsif bye?
        :bye
      end
    end

    def bye?
      !played? && won?
    end

    def winner
      case result.downcase
      when :white_won, :white_won_by_forfeit, "1", "1i", "w", "wi" then white
      when :black_won, :black_won_by_forfeit, "0", "0i", "b", "bi" then black
      end
    end

    def points_received
      @points_received ||= if won?
        1.0
      elsif draw?
        0.5
      else
        0.0
      end
    end

    def played?
      @played ||= played_results.include?(result)
    end

  private
    def played_results
      [:white_won, :draw, :black_won,
       "1", "½", "0",
       "W", "D", "B",
       "w", "d", "b"
      ]
    end

    def white
      players[0]
    end

    def black
      players[1]
    end

    def result
      pair.result
    end

    def players
      pair.players
    end

    def won?
      winner == player
    end

    def draw?
      ([:draw] + %w(½ d D)).include?(result)
    end
  end
end
