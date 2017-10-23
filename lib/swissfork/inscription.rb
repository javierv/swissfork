require "simple_initialize"

module Swissfork
  # Contains personal data related to a player.
  #
  # For now, it only contains the name and the rating.
  class Inscription
    # TODO: we currently ignore spliting name between first
    # name and last name
    initialize_with :rating, :name
    include Comparable

    def <=>(inscription)
      # TODO: implement properly, adding GM titles if necessary.
      [inscription.rating, name] <=> [rating, inscription.name]
    end
  end
end
