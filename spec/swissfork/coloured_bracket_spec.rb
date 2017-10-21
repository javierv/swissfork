require "spec_helper"
require "swissfork/bracket"
require "swissfork/player"

module Swissfork
  describe Bracket do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:bracket) { Bracket.for(players) }

    describe "#pairs with colours" do
      let(:players) { create_players(1..10) }

      context "homogeneous bracket" do
        before(:each) { players.each { |player| player.stub(points: 1) }}

        context "default exchange is OK" do
          before(:each) do
            players[0..4].each { |player| player.stub_preference(:white) }
            players[5..9].each { |player| player.stub_preference(:black) }
          end

          it "pairs players normally" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
          end
        end

        context "transpositions guarantee colour preferences" do
          before(:each) do
            players[0..3].each { |player| player.stub_preference(:white) }
            players[4].stub_preference(:black)
            players[5..7].each { |player| player.stub_preference(:black) }
            players[8].stub_preference(:white)
            players[9].stub_preference(:black)
          end

          it "pairs maximizing colour preferences" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 10], [9, 5]]
          end
        end
      end

      context "all players have the same colour preference" do
        let(:players) { create_players(1..4) }

        before(:each) do
          players.each { |player| player.stub(points: 1) }
          players.each { |player| player.stub_preference(:white) }
        end

        context "all players have the same preference degree" do
          before(:each) do
            players.each { |player| player.stub_degree(:strong) }
          end

          it "pairs giving priority to the higher players" do
            bracket.pair_numbers.should == [[1, 3], [2, 4]]
          end
        end

        context "the lower players have a stronger preference" do
          before(:each) do
            players[0..1].each { |player| player.stub_degree(:strong) }
            players[2..3].each { |player| player.stub_degree(:absolute) }
          end

          it "pairs giving priority to the higher players" do
            bracket.pair_numbers.should == [[3, 1], [4, 2]]
          end
        end
      end
    end
  end
end
