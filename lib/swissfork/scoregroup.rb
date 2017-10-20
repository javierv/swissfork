require "simple_initialize"
require "swissfork/bracket"
require "swissfork/completion"
require "swissfork/completion_permit"
require "swissfork/bye_permit"

module Swissfork
  # Holds information about a bracket and the rest of the
  # scoregroups we need to pair.
  #
  # Sometimes a bracket needs to know about other brackets;
  # for example, in criterias C.4 (penultimate bracket) and
  # C.7 (maximize pairs in the next bracket).
  class Scoregroup
    initialize_with :players, :round
    include Comparable

    def add_player(player)
      reset
      @players = (players + [player]).sort
    end

    def add_players(players)
      players.each { |player| add_player(player) }
    end

    def remove_players(players_to_remove)
      reset
      @players = players.reject { |player| players_to_remove.include?(player) }
    end

    def points
      bracket.points
    end

    def <=>(scoregroup)
      bracket <=> scoregroup.bracket
    end

    def pairs
      if last?
        bracket.downfloat_permit = ByePermit.new(players)
      else
        bracket.number_of_required_downfloats = number_of_required_downfloats
        bracket.downfloat_permit =
          CompletionPermit.new(players, remaining_players, bracket.number_of_required_downfloats)

        until(bracket.pairs && next_scoregroup_pairing_is_ok?)
          # Criteria C.7
          if bracket.pairs.to_a.empty?
            reduce_number_of_next_scoregroup_required_pairs
            bracket.reset_impossible_downfloats
          else
            bracket.mark_established_downfloats_as_impossible
          end
        end
      end

      bracket.pairs
    end

    def number_of_required_downfloats
      required_mdps = Completion.new(remaining_players).number_of_required_mdps

      if((players.count - required_mdps).odd?)
        required_mdps + 1
      else
        required_mdps
      end
    end

    def bracket
      @bracket ||= Bracket.for(players)
    end

    def leftovers
      bracket.leftovers.to_a
    end

    def move_leftovers_to_next_scoregroup
      next_scoregroup.add_players(leftovers)
      remove_players(leftovers)
    end

    def last?
      self == scoregroups.last
    end

    def pair_numbers
      pairs.map(&:numbers)
    end

    def leftover_numbers
      leftovers.map(&:number)
    end

  private
    def next_scoregroup
      scoregroups[next_scoregroup_index]
    end

    def index
      scoregroups.index(self)
    end

    def next_scoregroup_index
       index + 1
    end

    def hypothetical_next_players
      leftovers + next_scoregroup.players
    end

    def hypothetical_next_pairs
      Bracket.for(hypothetical_next_players).tap do |bracket|
        if next_scoregroup.last?
          bracket.downfloat_permit = ByePermit.new(hypothetical_next_players)
        end
      end.pairs
    end

    def hypothetical_remaining_players
      remaining_players + leftovers
    end

    def next_scoregroup_pairing_is_ok?
      remaining_players_complete_the_pairing? && next_scoregroup_meets_required_pairs?
    end

    def remaining_players_complete_the_pairing?
      Completion.new(hypothetical_remaining_players).ok?
    end

    def next_scoregroup_meets_required_pairs?
      hypothetical_next_pairs.to_a.count == number_of_next_scoregroup_required_pairs
    end

    def number_of_next_scoregroup_required_pairs
      @number_of_next_scoregroup_required_pairs ||= (bracket.number_of_required_downfloats + next_scoregroup.players.count) / 2
    end

    def reduce_number_of_next_scoregroup_required_pairs
      @number_of_next_scoregroup_required_pairs = number_of_next_scoregroup_required_pairs - 1
    end

    def remaining_players
      remaining_scoregroups.flat_map(&:players)
    end

    def remaining_scoregroups
      scoregroups[index+1..-1]
    end

    def scoregroups
      round.scoregroups
    end

    def reset
      @bracket = nil
    end
  end
end
