require "spec_helper"
require "swissfork/possible_pairs"
require "swissfork/player"

module Swissfork
  describe PossiblePairs do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:pairs) { PossiblePairs.new(players) }

    describe "#count" do
      let(:players) { create_players(1..10) }

      context "no incompatibilities" do
        it "returns 0" do
          pairs.incompatibilities.should == 0
        end
      end

      context "two players have only the same possible opponent" do
        before(:each) do
          players[0..1].each { |player| player.stub_opponents(players[0..8]) }
          players[2..8].each { |player| player.stub_opponents(players[0..1]) }
        end

        it "returns 2" do
          pairs.incompatibilities.should == 2
        end
      end

      context "two players have the same two possible opponents" do
        before(:each) do
          players[0..1].each { |player| player.stub_opponents(players[0..7]) }
          players[2..7].each { |player| player.stub_opponents(players[0..1]) }
        end

        it "returns 0" do
          pairs.incompatibilities.should == 0
        end

        context "and another players' possible opponents is one of those ones" do
          before(:each) do
            # 1 => 9, 10
            # 2 => 9, 10
            # 3 => 10
            players[0].stub_opponents(players[0..7])
            players[1].stub_opponents(players[0..7])
            players[2].stub_opponents(players[0..8])

            players[3..7].each { |player| player.stub_opponents(players[0..2]) }
          end

          it "returns 2" do
            pairs.incompatibilities.should == 2
          end
        end

        context "and two other players have three possible opponents" do
          before(:each) do
            # 1 => 9, 10
            # 2 => 9, 10
            # 3 => 8, 9, 10
            # 4 => 8, 9, 10
            players[0].stub_opponents(players[0..7])
            players[1].stub_opponents(players[0..7])
            players[2].stub_opponents(players[0..6])
            players[3].stub_opponents(players[0..6])

            players[4..6].each { |player| player.stub_opponents(players[0..3]) }
          end

          it "returns 2" do
            pairs.incompatibilities.should == 2
          end
        end
      end

      context "four players have the same two possible opponents" do
        before(:each) do
          players[0..3].each { |player| player.stub_opponents(players[0..7]) }
          players[4..7].each { |player| player.stub_opponents(players[0..3]) }
        end

        it "returns 2" do
          pairs.incompatibilities.should == 2
        end
      end

      context "six players can play against four opponents" do
        before(:each) do
          # 1 => 9, 10
          # 2 => 8, 9
          # 3 => 8, 10
          # 4 => 7, 10
          # 5 => 7, 9
          # 6 => 7, 8
          players[0].stub_opponents(players[0..7])
          players[1].stub_opponents(players[0..6] + [players[9]])
          players[2].stub_opponents(players[0..6] + [players[8]])
          players[3].stub_opponents(players[0..5] + players[7..8])
          players[4].stub_opponents(players[0..5] + [players[7], players[9]])
          players[5].stub_opponents(players[0..5] + players[8..9])

          players[6].stub_opponents(players[0..2])
          players[7].stub_opponents([players[0]] + players[3..4])
          players[8].stub_opponents(players[2..3] + [players[5]])
          players[9].stub_opponents([players[1]] + players[4..5])
        end

        it "returns 2" do
          pairs.incompatibilities.should == 2
        end
      end

      context "three players can only play against each other" do
        before(:each) do
          players[0..2].each { |player| player.stub_opponents(players[3..9]) }
          players[3..9].each { |player| player.stub_opponents(players[0..2]) }
        end

        it "returns 2" do
          pairs.incompatibilities.should == 2
        end
      end
    end

    describe "#count" do
      let(:players) { create_players(1..7) }

      context "all players can be paired" do
        it "returns half of the total number of players, rounding down" do
          pairs.count.should == 3
        end
      end

      context "some players can't be paired" do
        before(:each) do
          players[0..1].each { |player| player.stub_opponents(players[0..6]) }
          players[2..6].each { |player| player.stub_opponents(players[0..1]) }
        end

        it "returns half of the number of pairable players, rounding down" do
          pairs.count.should == 2
        end
      end
    end
  end
end
