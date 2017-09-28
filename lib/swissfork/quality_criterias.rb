module Swissfork
  # Checks quality of pairs following the quality criterias
  # described in FIDE Dutch System, sections C.6 to C.19.
  #
  # Criteria C.5 is already implemented in the main algorithm.
  class QualityCriterias
    initialize_with :bracket

    def ok?
      criterias.none? { |condition| send(condition) }
    end

    def worst_possible?
      criterias.empty?
    end

    def be_more_permissive
      criterias.pop
    end

    def include?(element)
      criterias.include?(element)
    end

    def s2_leftovers_can_downfloat?
      (s2_leftovers & possible_downfloaters).any?
    end

  private
    def criterias
      @criterias ||= [
        :any_players_descending_twice?,
        :same_downfloats_as_previous_round?,
        :same_upfloats_as_previous_round?,
        :same_downfloats_as_two_rounds_ago?,
        :same_upfloats_as_two_rounds_ago?
      ]
    end

    # C.6
    def any_players_descending_twice?
      leftovers.any? { |player| player.points > bracket.points }
    end

    # C.12
    def same_downfloats_as_previous_round?
      leftovers.any? { |player| player.descended_in_the_previous_round? }
    end

    # C.13
    def same_upfloats_as_previous_round?
      ascending_players.any? { |player| player.ascended_in_the_previous_round? }
    end

    # C.14
    def same_downfloats_as_two_rounds_ago?
      leftovers.any? { |player| player.descended_two_rounds_ago? }
    end

    # C.15
    def same_upfloats_as_two_rounds_ago?
      ascending_players.any? { |player| player.ascended_two_rounds_ago? }
    end

    def ascending_players
      heterogeneous_pairs.map(&:s2_player)
    end

    def heterogeneous_pairs
      pairs.select(&:heterogeneous?)
    end

    def s2_leftovers
      s2 & leftovers
    end

    def possible_downfloaters
      players.select do |player|
        !(
          include?(:same_downfloats_as_previous_round?) &&
          player.descended_in_the_previous_round?
        ) && !(
          include?(:same_downfloats_as_two_rounds_ago?) &&
          player.descended_two_rounds_ago?
        )
      end
    end

    def leftovers
      bracket.send(:still_unpaired_players)
    end

    def pairs
      bracket.send(:established_pairs)
    end

    def players
      bracket.players
    end

    def s2
      bracket.s2
    end
  end
end
