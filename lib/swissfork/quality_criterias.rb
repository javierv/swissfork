module Swissfork
  # Checks quality of pairs following the quality criterias
  # described in FIDE Dutch System, sections C.8 to C.19.
  #
  # Criterias C.5 to C.7 are implemented in the main algorithm.
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

    def s2_leftovers_can_downfloat?
      (pairable_s2_leftovers & possible_downfloaters).any?
    end

  private
    def criterias
      @criterias ||= [
        :same_downfloats_as_previous_round?,
        :same_upfloats_as_previous_round?,
        :same_downfloats_as_two_rounds_ago?,
        :same_upfloats_as_two_rounds_ago?
      ]
    end

    # C.12
    def same_downfloats_as_previous_round?
      pairable_leftovers.any? { |player| player.descended_in_the_previous_round? }
    end

    # C.13
    def same_upfloats_as_previous_round?
      ascending_players.any? { |player| player.ascended_in_the_previous_round? }
    end

    # C.14
    def same_downfloats_as_two_rounds_ago?
      pairable_leftovers.any? { |player| player.descended_two_rounds_ago? }
    end

    # C.15
    def same_upfloats_as_two_rounds_ago?
      ascending_players.any? { |player| player.ascended_two_rounds_ago? }
    end

    def ascending_players
      heterogeneous_pairs.map(&:last)
    end

    def heterogeneous_pairs
      pairs.select(&:heterogeneous?)
    end

    def pairable_s2_leftovers
      s2 & pairable_leftovers
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

    def include?(element)
      criterias.include?(element)
    end

    # TODO: is it OK to use "send" only because this is kind of a private
    # doing part of the logic in Bracket? It looks terrible anyway.
    def pairable_leftovers
      bracket.send(:pairable_players) & bracket.send(:still_unpaired_players)
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
