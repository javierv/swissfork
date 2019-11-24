require "create_players_helper"
require "swissfork/possible_pairs"

module Swissfork
  describe PossiblePairs do
    let(:pairs) { PossiblePairs.new(players) }

    describe "#count" do
      let(:players) { create_players(1..10) }

      context "no incompatibilities" do
        it "returns half of the players" do
          pairs.count.should eq 5
        end

        context "odd number of players" do
          let(:players) { create_players(1..9) }

          it "returns half of the players, rounding down" do
            pairs.count.should eq 4
          end
        end
      end

      context "two players have only the same possible opponent" do
        before do
          players[0..1].each_stub_opponents(players[0..8])
          players[2..8].each_stub_opponents(players[0..1])
        end

        it "leaves two players unpaired" do
          pairs.count.should eq 4
        end
      end

      context "two players have the same two possible opponents" do
        before do
          players[0..1].each_stub_opponents(players[0..7])
          players[2..7].each_stub_opponents(players[0..1])
        end

        it "shows no incompatibilities" do
          pairs.count.should eq 5
        end

        context "and another players' possible opponents is one of those ones" do
          before do
            # 1 => 9, 10
            # 2 => 9, 10
            # 3 => 10
            players[0].stub_opponents(players[0..7])
            players[1].stub_opponents(players[0..7])
            players[2].stub_opponents(players[0..8])

            players[3..7].each_stub_opponents(players[0..2])
            players[8].stub_opponents([players[0]])
          end

          it "can't pair all players" do
            pairs.count.should eq 4
          end

          context "the order of the players is different" do
            before do
              # 1 => 10
              # 2 => 9, 10
              # 3 => 9, 10
              players[0].stub_opponents(players[0..8])
              players[1].stub_opponents(players[0..7])
              players[2].stub_opponents(players[0..7])

              players[3..7].each_stub_opponents(players[0..2])
              players[8].stub_opponents([players[2]])
            end

            it "returns the same result" do
              pairs.count.should eq 4
            end
          end
        end

        context "and two other players have three possible opponents" do
          before do
            # 1 => 9, 10
            # 2 => 9, 10
            # 3 => 8, 9, 10
            # 4 => 8, 9, 10
            players[0].stub_opponents(players[0..7])
            players[1].stub_opponents(players[0..7])
            players[2].stub_opponents(players[0..6])
            players[3].stub_opponents(players[0..6])

            players[4..6].each_stub_opponents(players[0..3])
          end

          it "can't pair all players" do
            pairs.count.should eq 4
          end
        end
      end

      context "four players have the same two possible opponents" do
        before do
          players[0..3].each_stub_opponents(players[0..7])
          players[4..7].each_stub_opponents(players[0..3])
        end

        it "can't pair two players" do
          pairs.count.should eq 4
        end
      end

      context "six players can play against four opponents" do
        before do
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

        it "can't pair two players" do
          pairs.count.should eq 4
        end
      end

      context "three players can only play against each other" do
        before do
          players[0..2].each_stub_opponents(players[3..9])
          players[3..9].each_stub_opponents(players[0..2])
        end

        it "can't pair two players" do
          pairs.count.should eq 4
        end
      end
    end

    describe "#enough_players_to_guarantee_pairing" do
      let(:players) { create_players(1..11) }

      context "no incompatibilities" do
        it "returns true" do
          pairs.enough_players_to_guarantee_pairing?.should be true
        end
      end

      context "one player can play against half of the players, rounding down" do
        before do
          players[0].stub_opponents(players[0..5])
          players[1..5].each_stub_opponents([players[0]])
        end

        it "returns true" do
          pairs.enough_players_to_guarantee_pairing?.should be true
        end
      end

      context "one player can play against less than half of the players" do
        before do
          players[0].stub_opponents(players[0..6])
          players[1..6].each_stub_opponents([players[0]])
        end

        it "returns false" do
          pairs.enough_players_to_guarantee_pairing?.should be false
        end
      end

      context "there are players with absolute preference" do
        let(:players) { create_players(1..4) }

        context "all players have an absolute preference" do
          before do
            players.each_stub_degree(:absolute)
          end

          context "with the same colour" do
            before do
              players.each_stub_preference(:white)
            end

            it "returns false" do
              pairs.enough_players_to_guarantee_pairing?.should be false
            end
          end

          context "with different colour" do
            before do
              players[0..1].each_stub_preference(:white)
              players[2..3].each_stub_preference(:black)
            end

            it "returns true" do
              pairs.enough_players_to_guarantee_pairing?.should be true
            end
          end
        end
      end

      context "two players" do
        let(:players) { create_players(1..2) }

        context "they've played against each other" do
          before do
            players[0].stub_opponents([players[1]])
            players[1].stub_opponents([players[0]])
          end

          it "returns false" do
            pairs.enough_players_to_guarantee_pairing?.should be false
          end
        end

        context "they're topscorers" do
          before { players[0].stub(topscorer?: true) }

          it "returns true" do
            pairs.enough_players_to_guarantee_pairing?.should be true
          end
        end
      end
    end
  end
end
