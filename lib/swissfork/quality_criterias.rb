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

    def possible_downfloats
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

    def include?(element)
      criterias.include?(element)
    end

    def pairable_leftovers
      bracket.pairable_hypothetical_leftovers
    end

    # TODO: this isn't very elegant.
    def pairs
      bracket.send(:established_pairs)
    end

    def players
      bracket.players
    end
  end
end
