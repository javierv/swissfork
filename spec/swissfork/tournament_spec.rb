require "spec_helper"
require "swissfork/tournament"
require "swissfork/inscription"

module Swissfork
  describe Tournament do
    let(:tournament) { Tournament.new(9) }

    describe "#players" do
      before(:each) do
        tournament.add_inscription(Inscription.new(2300, "Louis Armstrong"))
        tournament.add_inscription(Inscription.new(2200, "Aretha Franklin"))
        tournament.add_inscription(Inscription.new(2400, "Django Reinhardt"))
        tournament.add_inscription(Inscription.new(2130, "Ludwig van Beethoven"))
      end

      context "the first round hasn't started yet" do
        it "hasn't defined the players yet" do
          tournament.players.should be nil
        end
      end

      context "the first round has started" do
        before(:each) { tournament.start_round }

        it "orders the players and gives them numbers" do
          tournament.players.map(&:number).should == [1, 2, 3, 4]
          tournament.players.map(&:rating).should == [2400, 2300, 2200, 2130]
        end
      end
    end
  end
end
