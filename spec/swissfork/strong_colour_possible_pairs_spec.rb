require "spec_helper"
require "swissfork/strong_colour_possible_pairs"
require "swissfork/player"

module Swissfork
  describe StrongColourPossiblePairs do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:pairs) { StrongColourPossiblePairs.new(players) }

    describe "#count" do
      let(:players) { create_players(1..10) }

      context "all players have the same colour preference" do
        before(:each) { players.each_stub_preference(:white) }

        context "all preferences are strong" do
          before(:each) { players.each_stub_degree(:strong) }

          it "returns zero" do
            pairs.count.should == 0
          end
        end

        context "all preferences are mild" do
          before(:each) { players.each_stub_degree(:mild) }

          it "returns the number of pairs" do
            pairs.count.should == 5
          end
        end

        context "some preferences are mild" do
          before(:each) { players[0..1].each_stub_degree(:mild) }

          it "returns the number of pairs with players with mild preference" do
            pairs.count.should == 2
          end

          context "players with mild preference must play each other" do
            before(:each) do
              players[0..1].each_stub_opponents(players[2..9])
              players[2..9].each_stub_opponents(players[0..1])
            end

            it "returns the number of pairs with players with mild preference" do
              pairs.count.should == 1
            end
          end
        end
      end
    end
  end
end
