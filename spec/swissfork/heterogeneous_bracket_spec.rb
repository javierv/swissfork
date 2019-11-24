require "create_players_helper"
require "swissfork/bracket"

module Swissfork
  describe Bracket do
    let(:bracket) { Bracket.for(players) }

    describe "#number_of_moved_down_players" do
      let(:players) { create_players(1..6) }

      before do
        players.each_stub(points: 1)
        players.first.stub(points: 1.5)
      end

      it "returns the number of descended players" do
        bracket.number_of_moved_down_players.should eq 1
      end
    end

    describe "#pair_numbers" do
      context "even number of players" do
        let(:players) { create_players(1..10) }
        before do
          players[0].stub(points: 1.5)
          players[1].stub(points: 1.5)
        end

        context "the resulting homogeneous group is possible to pair" do
          it "pairs the descended players with the highest non-descended players" do
            bracket.pair_numbers.should eq [[1, 3], [2, 4], [5, 8], [6, 9], [7, 10]]
          end
        end

        context "the resulting homogeneous group isn't possible to pair" do
          before do
            players[4].stub_opponents(players[5..9])
            players[5..9].each_stub_opponents([players[4]])
          end

          it "redoes the pairing of the descended players" do
            bracket.pair_numbers.should eq [[1, 3], [2, 5], [4, 8], [6, 9], [7, 10]]
          end
        end

        context "no moved down players can't be paired" do
          before do
            players[0..1].each_stub_opponents(players[0..9])
            players[2..9].each_stub_opponents(players[0..1])
          end

          it "moves those players down and pairs the rest" do
            bracket.pair_numbers.should eq [[3, 7], [4, 8], [5, 9], [6, 10]]
            bracket.leftover_numbers.should eq [1, 2]
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..11) }

        before do
          players[0].stub(points: 1.5)
          players[1].stub(points: 1.5)
        end

        context "one of the descended players can't be paired" do
          before do
            players[0].stub_opponents(players[1..10])
            players[1..10].each_stub_opponents([players[0]])
          end

          it "pairs the rest of the players" do
            bracket.pair_numbers.should eq [[2, 3], [4, 8], [5, 9], [6, 10], [7, 11]]
          end

          it "downfloats the descended player" do
            bracket.leftover_numbers.should eq [1]
          end
        end

        context "same possible opponent for two moved down players" do
          before do
            players[0..1].each_stub_opponents(players[0..9])
            players[2..9].each_stub_opponents(players[0..1])
          end

          it "downfloats the lower player and pairs the rest" do
            bracket.pair_numbers.should eq [[1, 11], [3, 7], [4, 8], [5, 9], [6, 10]]
            bracket.leftover_numbers.should eq [2]
          end

          context "the lower player has already downfloated" do
            before do
              players[1].stub(floats: [:down])
            end

            it "downfloats the higher player" do
              bracket.pair_numbers.should eq [[2, 11], [3, 7], [4, 8], [5, 9], [6, 10]]
              bracket.leftover_numbers.should eq [1]
            end

            context "the higher player has more points" do
              before { players[0].stub(points: 3) }

              it "gives priority to the player with more points (C.6)" do
                bracket.pair_numbers.should eq [[1, 11], [3, 7], [4, 8], [5, 9], [6, 10]]
                bracket.leftover_numbers.should eq [2]
              end
            end
          end
        end

        context "the lowest player has already downfloated" do
          before { players[10].stub(floats: [:down]) }

          it "downfloats a different player" do
            bracket.leftover_numbers.should eq [10]
            bracket.pair_numbers.should eq [[1, 3], [2, 4], [5, 8], [6, 9], [7, 11]]
          end
        end

        context "all players have downfloated except the highest S2 one" do
          before do
            players[3..10].each_stub(floats: [:down])
          end

          it "downfloats that player" do
            bracket.leftover_numbers.should eq [3]
            bracket.pair_numbers.should eq [[1, 4], [2, 5], [6, 9], [7, 10], [8, 11]]
          end
        end

        context "all players in S2 have downfloated" do
          before do
            players[2..10].each_stub(floats: [:down])
          end

          it "downfloats the lowest player" do
            bracket.leftover_numbers.should eq [11]
            bracket.pair_numbers.should eq [[1, 3], [2, 4], [5, 8], [6, 9], [7, 10]]
          end
        end

        context "moved down players have different points" do
          before do
            players[0..1].each_stub(points: 3)
            players[2..3].each_stub(points: 2)
          end

          context "three downfloats needed" do
            before do
              players[0..3].each_stub_opponents(players - [players[4]])
              players[5..9].each_stub_opponents(players[0..3])
            end

            context "only a player with less points didn't downfloat" do
              before do
                players[0..2].each_stub(floats: [:down])
              end

              it "pairs the first player" do
                bracket.pair_numbers.should eq [[1, 5], [6, 9], [7, 10], [8, 11]]
              end
            end

            context "the second player downfloated" do
              before do
                players[1].stub(floats: [:down])
              end

              it "pairs the second player" do
                bracket.pair_numbers.should eq [[2, 5], [6, 9], [7, 10], [8, 11]]
              end
            end
          end
        end
      end

      context "half of the players are moved down players" do
        let(:players) { create_players(1..10) }

        before do
          players[0..4].each_stub(points: 1.5)
          players[5..9].each_stub(points: 1)
        end

        it "pairs the bracket like a homogeneous bracket" do
          bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
        end

        context "one of the players can't be paired" do
          before do
            players[0].stub_opponents(players[1..9])
            players[1..9].each_stub_opponents([players[0]])
          end

          it "doesn't pair that player" do
            bracket.pair_numbers.should eq [[2, 6], [3, 7], [4, 8], [5, 9]]
          end

          it "moves that player and the last player down" do
            bracket.leftover_numbers.should eq [1, 10]
          end
        end
      end

      context "more than half the players moved down players" do
        let(:players) { create_players(1..12) }

        before do
          players[0..7].each_stub(points: 1.5)
          players[8..11].each_stub(points: 1)
        end

        context "the first four moved down player can't be paired" do
          before do
            players[0..3].each_stub_opponents(players[0..11])
            players[4..11].each_stub_opponents(players[0..3])
          end

          it "moves those players down and pairs the rest" do
            bracket.pair_numbers.should eq [[5, 9], [6, 10], [7, 11], [8, 12]]
            bracket.leftover_numbers.should eq [1, 2, 3, 4]
          end
        end
      end
    end
  end
end
