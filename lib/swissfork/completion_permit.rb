require "swissfork/completion"
require "swissfork/downfloat_permit"

module Swissfork
  # This permit allows downfloat combinations which
  # complete the pairing.
  class CompletionPermit < DownfloatPermit
    initialize_with :players, :remaining_players, :number_of_downfloats

  private
    def permit_condition(downfloats)
      Completion.new(downfloats + remaining_players).ok?
    end
  end
end
