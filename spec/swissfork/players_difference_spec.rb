require "swissfork/players_difference"

module Swissfork
  describe PlayersDifference do
    describe "#difference" do
      context "one player per gruoup" do
        context "first player has a smaller number" do
          let(:s1_player) { [double(number: 1)] }
          let(:s2_player) { [double(number: 3)] }
          let(:difference) { PlayersDifference.new(s1_player, s2_player) }

          it "returns the difference between the numbers" do
            difference.difference.should == 2
          end
        end

        context "first player has a bigger number" do
          let(:s1_player) { [double(number: 7)] }
          let(:s2_player) { [double(number: 3)] }
          let(:difference) { PlayersDifference.new(s1_player, s2_player) }

          it "returns the difference between the numbers" do
            difference.difference.should == 4
          end
        end
      end

      context "several players per group" do
        let(:s1_players) { [double(number: 4), double(number: 5)] }
        let(:s2_players) { [double(number: 6), double(number: 8)] }
        let(:difference) { PlayersDifference.new(s1_players, s2_players) }

        it "returns the difference between the sum of each group" do
          difference.difference.should == 5
        end
      end
    end

    describe "#<=>" do
      context "one player per gruoup" do
        context "different differences between players" do
          let(:s1_player) { [double(number: 1)] }
          let(:smaller_s2_player) { [double(number: 3)] }
          let(:bigger_s2_player) { [double(number: 4)] }

          it "the one with the smaller difference is smaller" do
            PlayersDifference.new(s1_player, smaller_s2_player).should be <
            PlayersDifference.new(s1_player, bigger_s2_player)
          end
        end

        context "same differences between players" do
          let(:smaller_s1_player) { [double(number: 1)] }
          let(:bigger_s1_player) { [double(number: 2)] }
          let(:smaller_s2_player) {  [double(number: 3)] }
          let(:bigger_s2_player) { [double(number: 4)] }

          it "the one with the bigger s1 player is smaller" do
            PlayersDifference.new(bigger_s1_player, bigger_s2_player).should be < PlayersDifference.new(smaller_s1_player, smaller_s2_player)
          end
        end
      end

      context "several players per gruop" do
        context "different differences between players" do
          let(:s1_players) { [double(number: 1), double(number: 2)] }
          let(:smaller_s2_players) { [double(number: 3), double(number: 4)] }
          let(:bigger_s2_players) { [double(number: 5), double(number: 6)] }

          it "the one with the smaller difference is smaller" do
            PlayersDifference.new(s1_players, smaller_s2_players).should be <
            PlayersDifference.new(s1_players, bigger_s2_players)
          end
        end

        context "same differences between players, same S2 players" do
          let(:smaller_s1_players) { [double(number: 1), double(number: 4)] }
          let(:bigger_s1_players) { [double(number: 2), double(number: 3)] }
          let(:s2_players) { [double(number: 5), double(number: 6)] }

          it "the one with the biggest difference between S1 players is smaller" do
            PlayersDifference.new(smaller_s1_players, s2_players).should be <
            PlayersDifference.new(bigger_s1_players, s2_players)
          end
        end

        context "same differences between players, same S1 players" do
          let(:s1_players) { [double(number: 1), double(number: 2)] }
          let(:smaller_s2_players) { [double(number: 3), double(number: 6)] }
          let(:bigger_s2_players) { [double(number: 4), double(number: 5)] }

          it "the one with the lowest difference between S2 players is smaller" do
            PlayersDifference.new(s1_players, bigger_s2_players).should be <
            PlayersDifference.new(s1_players, smaller_s2_players)
          end
        end

        context "same differences between players, different S1 and S2 players" do
          let(:smaller_s1_players) { [double(number: 1), double(number: 4)] }
          let(:bigger_s1_players) { [double(number: 2), double(number: 3)] }
          let(:smaller_s2_players) { [double(number: 3), double(number: 6)] }
          let(:bigger_s2_players) { [double(number: 4), double(number: 5)] }

          it "the one with the biggest difference between S1 players is smaller" do
            PlayersDifference.new(smaller_s1_players, smaller_s2_players).should be <
            PlayersDifference.new(bigger_s1_players, bigger_s2_players)
          end
        end
      end
    end
  end
end
