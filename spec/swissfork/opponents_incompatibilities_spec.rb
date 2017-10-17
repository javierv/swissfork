require "spec_helper"
require "swissfork/opponents_incompatibilities"
require "swissfork/player"

module Swissfork
  describe OpponentsIncompatibilities do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:incompatibilities) { OpponentsIncompatibilities.new(players) }

    describe "#count" do
      let(:players) { create_players(1..10) }

      context "no incompatibilities" do
        it "returns 0" do
          incompatibilities.count.should == 0
        end
      end

      context "two players have only the same possible opponent" do
        before(:each) do
          players[0..1].each { |player| player.stub_opponents(players[0..8]) }
          players[2..8].each { |player| player.stub_opponents(players[0..1]) }
        end

        it "returns 1" do
          incompatibilities.count.should == 1
        end
      end

      context "two players have the same two possible opponents" do
        before(:each) do
          players[0..1].each { |player| player.stub_opponents(players[0..7]) }
          players[2..7].each { |player| player.stub_opponents(players[0..1]) }
        end

        it "returns 0" do
          incompatibilities.count.should == 0
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

          it "returns 1" do
            incompatibilities.count.should == 1
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

          it "returns 1" do
            incompatibilities.count.should == 1
          end
        end
      end

      context "four players have the same two possible opponents" do
        before(:each) do
          players[0..3].each { |player| player.stub_opponents(players[0..7]) }
          players[4..7].each { |player| player.stub_opponents(players[0..3]) }
        end

        it "returns 2" do
          incompatibilities.count.should == 2
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
          incompatibilities.count.should == 2
        end
      end
    end

    describe "#bye_can_be_selected?" do
      context "even number of players" do
        let(:players) { create_players(1..6) }

        context "all players had byes" do
          before(:each) do
            players[0..5].each { |player| player.stub(had_bye?: true) }
          end

          it "returns true" do
            incompatibilities.bye_can_be_selected?.should be true
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..7) }

        context "not all players had byes" do
          before(:each) do
            players[0..5].each { |player| player.stub(had_bye?: true) }
          end

          context "no pairing incompatibilities" do
            it "returns true" do
              incompatibilities.bye_can_be_selected?.should be true
            end
          end

          context "pairing incompatibilities" do
            before(:each) do
              players[0].stub_opponents(players[1..5])
              players[1..5].each { |player| player.stub_opponents([players[0]]) }
            end

            it "returns false" do
              incompatibilities.bye_can_be_selected?.should be false
            end
          end
        end

        context "all players had byes" do
          before(:each) do
            players[0..6].each { |player| player.stub(had_bye?: true) }
          end

          it "returns true" do
            incompatibilities.bye_can_be_selected?.should be false
          end
        end
      end
    end

    describe "#all_players_can_be_paired?" do
      let(:players) { create_players(1..12) }

      context "pairable players" do
        it "returns true" do
          incompatibilities.all_players_can_be_paired?.should be true
        end
      end

      context "existing opponents still make the players pairable" do
        before(:each) do
          players[11].stub_opponents(players[6..10])
          players[6..10].each { |player| player.stub_opponents([players[11]]) }
        end

        it "returns true" do
          incompatibilities.all_players_can_be_paired?.should be true
        end
      end

      context "completely unpairable players" do
        before(:each) do
          players[0..11].each { |player| player.stub_opponents(players[0..11]) }
        end

        it "returns false" do
          incompatibilities.all_players_can_be_paired?.should be false
        end
      end

      context "one player can't be paired at all" do
        before(:each) do
          players[11].stub_opponents(players[0..10])
          players[0..10].each { |player| player.stub_opponents([players[11]]) }
        end

        it "returns false" do
          incompatibilities.all_players_can_be_paired?.should be false
        end
      end

      context "two players have the same possible opponent" do
        before(:each) do
          players[10..11].each { |player| player.stub_opponents(players[1..11]) }
          players[1..9].each { |player| player.stub_opponents(players[10..11]) }
        end

        it "returns false" do
          incompatibilities.all_players_can_be_paired?.should be false
        end
      end
    end

    # TODO: these tests come from Bracket,
    # and they're probably redundant.
    describe "#number_of_compatible_pairs" do
      let(:players) { create_players(1..6) }

      context "all players can be paired" do
        it "returns half of the total number of players" do
          incompatibilities.number_of_compatible_pairs.should == 3
        end

        context "odd number of players" do
          let(:players) { create_players(1..7) }

          it "returns half of the total number of players, rounding down" do
            incompatibilities.number_of_compatible_pairs.should == 3
          end
        end
      end

      context "some players can't be paired" do
        before(:each) do
          players[0].stub_opponents(players[1..5])
          players[1..5].each { |player| player.stub_opponents([players[0]]) }
        end

        it "returns half of the number of pairable players, rounding down" do
          incompatibilities.number_of_compatible_pairs.should == 2
        end
      end

      context "two players can only be paired to the same opponent" do
        before(:each) do
          players[0..1].each { |player| player.stub_opponents(players[0..4]) }
          players[2..4].each { |player| player.stub_opponents(players[0..1]) }
        end

        it "counts only one of those players as pairable" do
          incompatibilities.number_of_compatible_pairs.should == 2
        end
      end

      context "five players can only be paired to the same opponent" do
        before(:each) do
          players[0..4].each { |player| player.stub_opponents(players[0..4]) }
        end

        it "counts only one of those players as pairable" do
          incompatibilities.number_of_compatible_pairs.should == 1
        end
      end

      context "three players can only be paired to the same two opponents" do
        let(:players) { create_players(1..8) }

        before(:each) do
          players[0].stub_opponents(players[0..3] + players[6..7])
          players[1].stub_opponents(players[0..3] + players[6..7])
          players[2].stub_opponents(players[0..3] + players[6..7])

          # Rest of the pairs are there just to complicate things
          players[3].stub_opponents(players[0..2])
          players[4].stub_opponents(players[4..7])
          players[5].stub_opponents(players[4..7])
          players[6].stub_opponents(players[0..2] + players[4..5])
          players[7].stub_opponents(players[0..2] + players[4..5])
        end

        it "counts only two of those players as pairable" do
          incompatibilities.number_of_compatible_pairs.should == 3
        end

        context "one of the players can also be paired to another one" do
          before(:each) do
            players[2].stub_opponents(players[0..2] + players[6..7])
            players[3].stub_opponents(players[0..1])
          end

          it "counts all players as pairable" do
            incompatibilities.number_of_compatible_pairs.should == 4
          end
        end
      end
    end
  end
end

