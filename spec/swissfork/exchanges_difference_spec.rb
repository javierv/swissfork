require "spec_helper"
require "swissfork/exchanges_difference"

module Swissfork
  describe ExchangesDifference do
    def player_with_number(number)
      double(bsn: number)
    end

    describe "#difference" do
      context "one player per gruoup" do
        context "first player has a smaller number" do
          let(:s1_player) { [player_with_number(1)] }
          let(:s2_player) { [player_with_number(3)] }
          let(:difference) { ExchangesDifference.new(s1_player, s2_player) }

          it "returns the difference between the numbers" do
            difference.difference.should == 2
          end
        end

        context "first player has a bigger number" do
          let(:s1_player) { [player_with_number(7)] }
          let(:s2_player) { [player_with_number(3)] }
          let(:difference) { ExchangesDifference.new(s1_player, s2_player) }

          it "returns the difference between the numbers" do
            difference.difference.should == 4
          end
        end
      end

      context "several players per group" do
        let(:s1_players) { [player_with_number(4), player_with_number(5)] }
        let(:s2_players) { [player_with_number(6), player_with_number(8)] }
        let(:difference) { ExchangesDifference.new(s1_players, s2_players) }

        it "returns the difference between the sum of each group" do
          difference.difference.should == 5
        end
      end
    end

    describe "#<=>" do
      context "one player per gruoup" do
        context "different differences between players" do
          let(:s1_player) { [player_with_number(1)] }
          let(:smaller_s2_player) { [player_with_number(3)] }
          let(:bigger_s2_player) { [player_with_number(4)] }

          it "the one with the smaller difference is smaller" do
            ExchangesDifference.new(s1_player, smaller_s2_player).should be <
              ExchangesDifference.new(s1_player, bigger_s2_player)
          end
        end

        context "same differences between players" do
          let(:smaller_s1_player) { [player_with_number(1)] }
          let(:bigger_s1_player) { [player_with_number(2)] }
          let(:smaller_s2_player) { [player_with_number(3)] }
          let(:bigger_s2_player) { [player_with_number(4)] }

          it "the one with the bigger s1 player is smaller" do
            ExchangesDifference.new(bigger_s1_player, bigger_s2_player).should be <
              ExchangesDifference.new(smaller_s1_player, smaller_s2_player)
          end
        end
      end

      context "several players per gruop" do
        context "different differences between players" do
          let(:s1_players) { [player_with_number(1), player_with_number(2)] }
          let(:smaller_s2_players) { [player_with_number(3), player_with_number(4)] }
          let(:bigger_s2_players) { [player_with_number(5), player_with_number(6)] }

          it "the one with the smaller difference is smaller" do
            ExchangesDifference.new(s1_players, smaller_s2_players).should be <
              ExchangesDifference.new(s1_players, bigger_s2_players)
          end
        end

        context "same differences between players, same S2 players" do
          let(:bigger_s1_players) { [player_with_number(1), player_with_number(4)] }
          let(:smaller_s1_players) { [player_with_number(2), player_with_number(3)] }
          let(:s2_players) { [player_with_number(5), player_with_number(6)] }

          it "the one with the biggest S1 player is smaller" do
            ExchangesDifference.new(bigger_s1_players, s2_players).should be <
              ExchangesDifference.new(smaller_s1_players, s2_players)
          end
        end

        context "same differences between players, same S1 players" do
          let(:s1_players) { [player_with_number(1), player_with_number(2)] }
          let(:smaller_s2_players) { [player_with_number(3), player_with_number(6)] }
          let(:bigger_s2_players) { [player_with_number(4), player_with_number(5)] }

          it "the one with the smallest S2 player is smaller" do
            ExchangesDifference.new(s1_players, smaller_s2_players).should be <
              ExchangesDifference.new(s1_players, bigger_s2_players)
          end
        end

        context "same differences between players, different S1 and S2 players" do
          let(:bigger_s1_players) { [player_with_number(1), player_with_number(4)] }
          let(:smaller_s1_players) { [player_with_number(2), player_with_number(3)] }
          let(:bigger_s2_players) { [player_with_number(3), player_with_number(6)] }
          let(:smaller_s2_players) { [player_with_number(4), player_with_number(5)] }

          it "the one with the biggest S1 player is smaller" do
            ExchangesDifference.new(bigger_s1_players, bigger_s2_players).should be <
              ExchangesDifference.new(smaller_s1_players, smaller_s2_players)
          end
        end

        context "same differences between players, highest S1 player is the same" do
          let(:smaller_s1_players) { [player_with_number(3), player_with_number(5)] }
          let(:bigger_s1_players) { [player_with_number(4), player_with_number(5)] }
          let(:smaller_s2_players) { [player_with_number(6), player_with_number(7)] }
          let(:bigger_s2_players) { [player_with_number(6), player_with_number(8)] }

          it "the one with the bigger S1 players is smaller" do
            ExchangesDifference.new(bigger_s1_players, bigger_s2_players).should be <
              ExchangesDifference.new(smaller_s1_players, smaller_s2_players)
          end
        end
      end
    end
  end
end
