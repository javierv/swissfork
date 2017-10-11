require "spec_helper"
require "swissfork/round"
require "swissfork/player"

module Swissfork
  describe Round do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:round) { Round.new(players) }

    describe "#bye" do
      context "even number of players" do
        let(:players) { create_players(1..10) }

        it "returns nil" do
          round.bye.should == nil
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..11) }

        it "returns the unpaired player" do
          round.bye.number.should == 11
        end
      end
    end

    describe "#pairs with byes" do
      let(:players) { create_players(1..11) }

      context "a player has already had a bye" do
        before(:each) { players[10].stub(had_bye?: true) }

        it "another player gets the bye" do
          round.bye.number.should == 10
          round.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 11]]
        end
      end

      context "a player downfloated in the previous round" do
        before(:each) do
          players[10].stub(floats: [:down])
        end

        it "another player gets the bye" do
          round.bye.number.should == 10
          round.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 11]]
        end
      end

      context "penultimate bracket has an even number of players" do
        before(:each) do
          players[0..5].each { |player| player.stub(points: 1) }
          players[6..10].each { |player| player.stub(points: 0) }
        end

        context "all players in the last bracket had byes" do
          before(:each) do
            players[6..10].each { |player| player.stub(had_bye?: true) }
          end

          it "gives the bye to a player from the previous bracket" do
            round.bye.number.should == 6
            round.pair_numbers.should == [[1, 3], [2, 4], [5, 7], [8, 10], [9, 11]]
          end
        end
      end

      context "penultimate bracket has an odd number of players" do
        before(:each) do
          players[0..6].each { |player| player.stub(points: 1) }
          players[7..10].each { |player| player.stub(points: 0) }
        end

        context "all players in the last bracket had byes" do
          before(:each) do
            players[7..10].each { |player| player.stub(had_bye?: true) }
          end

          it "gives the bye to a player from the previous bracket" do
            round.bye.number.should == 7
            round.pair_numbers.should == [[1, 4], [2, 5], [3, 6], [8, 10], [9, 11]]
          end
        end
      end
    end
  end
end
