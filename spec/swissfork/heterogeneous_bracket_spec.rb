require "create_players_helper"
require "swissfork/bracket"

module Swissfork
  describe Bracket do
    let(:bracket) { Bracket.for(players) }

    describe "#number_of_moved_down_players" do
      let(:players) { create_players(1..6) }

      before(:each) do
        players.each_stub(points: 1)
        players.first.stub(points: 1.5)
      end

      it "returns the number of descended players" do
        bracket.number_of_moved_down_players.should == 1
      end
    end

    describe "#number_of_moved_down_compatible_pairs" do
      let(:players) { create_players(1..10) }

      before(:each) do
        players[0..2].each_stub(points: 1.5)
        players[3..9].each_stub(points: 1)
      end

      context "all moved down players can be paired" do
        before(:each) do
          players[0].stub_opponents(players[1..2])
          players[1].stub_opponents([players[0], players[2]])
          players[2].stub_opponents(players[0..1])
        end

        it "returns the number of moved down players" do
          bracket.number_of_moved_down_compatible_pairs.should == 3
        end
      end

      context "there are more moved down players than resident players" do
        let(:players) { create_players(1..5) }

        before(:each) do
          players[0..2].each_stub(points: 1.5)
          players[3..4].each_stub(points: 1)
          players[0].stub_opponents(players[1..2])
          players[1].stub_opponents([players[0], players[2]])
          players[2].stub_opponents(players[0..1])
        end

        it "returns the number of resident players" do
          bracket.number_of_moved_down_compatible_pairs.should == 2
        end
      end

      context "one of the moved down players can't be paired" do
        before(:each) do
          players[0].stub_opponents(players[1..9])
          players[1].stub_opponents([players[0], players[2]])
          players[2].stub_opponents(players[0..1])
          players[3..9].each_stub_opponents([players[0]])
        end

        it "doesn't count that player as pairable" do
          bracket.number_of_moved_down_compatible_pairs.should == 2
        end
      end

      context "two of the moved down players can't be paired" do
        before(:each) do
          players[0..1].each_stub_opponents(players[0..9])
          players[2].stub_opponents(players[0..1])
          players[3..9].each_stub_opponents(players[0..1])
        end

        it "doesn't count those players as pairable" do
          bracket.number_of_moved_down_compatible_pairs.should == 1
        end
      end

      context "two players can only be paired to the same opponent" do
        before(:each) do
          players[0..1].each_stub_opponents(players[0..8])
          players[2].stub_opponents(players[0..1])
          players[3..8].each_stub_opponents(players[0..1])
        end

        it "counts only one of those players as pairable" do
          bracket.number_of_moved_down_compatible_pairs.should == 2
        end
      end

      context "three players can only be paired to the same two opponents" do
        let(:players) { create_players(1..8) }

        before(:each) do
          players[0..2].each_stub_opponents(players[0..7])
          players[3..7].each_stub_opponents(players[0..2])
        end

        it "counts only two of those players as pairable" do
          bracket.number_of_possible_pairs.should == 2
        end
      end
    end

    describe "#allowed_downfloats" do
      let(:players) { create_players(1..10) }

      def players_sets(*indices_groups)
        Set.new indices_groups.map do |indices|
          Set.new(indices.map { |index| players[index] })
        end
      end

      before(:each) do
        players[0..1].each_stub(points: 3)
        players[2..3].each_stub(points: 2)
        players[4..9].each_stub(points: 1)
      end

      context "one downfloat needed" do
        before(:each) { bracket.stub(number_of_required_moved_down_downfloats: 1) }

        context "only one player can downfloat" do
          before(:each) do
            bracket.stub(allowed_homogeneous_downfloats:
              players_sets([0, 5, 8], [4, 7, 9], [7, 0, 9], [5, 6, 8]))
          end

          it "returns the downfloats including that player" do
            bracket.allowed_downfloats.should == players_sets([0, 5, 8], [7, 0, 9])
          end

          context "all players can downfloat" do
            before(:each) do
              bracket.stub(allowed_homogeneous_downfloats:
                players_sets([0, 5, 8], [1, 7, 9], [2, 7, 9], [3, 6, 8]))
            end

            it "returns downfloats including players with less points" do
              bracket.allowed_downfloats.should == players_sets([2, 7, 9], [3, 6, 8])
            end
          end
        end
      end

      context "three downfloats needed" do
        before(:each) { bracket.stub(number_of_required_moved_down_downfloats: 3) }

        context "only combinations includes both players with more points" do
          before(:each) do
            bracket.stub(allowed_homogeneous_downfloats:
              players_sets([0, 1, 2, 4], [1, 7, 8, 9], [0, 1, 3, 9], [1, 2, 6, 8])
            )
          end

          it "returns downfloats having three moved down players" do
            bracket.allowed_downfloats.should == players_sets([0, 1, 2, 4], [0, 1, 3, 9])
          end
        end

        context "combinations include both players with less points" do
          before(:each) do
            bracket.stub(allowed_homogeneous_downfloats:
              players_sets([0, 1, 2, 4], [1, 7, 8, 9], [0, 2, 3, 9], [1, 2, 3, 8])
            )
          end

          it "returns downfloats having both players with less points" do
            bracket.allowed_downfloats.should == players_sets([0, 2, 3, 9], [1, 2, 3, 8])
          end
        end

        context "combinations include all players" do
          before(:each) do
            bracket.stub(allowed_homogeneous_downfloats:
              players_sets([0, 1, 2, 4], [0, 1, 2, 3], [0, 2, 3, 9], [1, 2, 3, 8])
            )
          end

          it "returns downfloats having both players with less points" do
            bracket.allowed_downfloats.should == players_sets([0, 2, 3, 9], [1, 2, 3, 8])
          end
        end
      end
    end

    describe "#pair_numbers" do
      context "even number of players" do
        let(:players) { create_players(1..10) }
        before(:each) do
          players[0].stub(points: 1.5)
          players[1].stub(points: 1.5)
        end

        context "the resulting homogeneous group is possible to pair" do
          it "pairs the descended players with the highest non-descended players" do
            bracket.pair_numbers.should == [[1, 3], [2, 4], [5, 8], [6, 9], [7, 10]]
          end
        end

        context "the resulting homogeneous group isn't possible to pair" do
          before(:each) do
            players[4].stub_opponents(players[5..9])
            players[5..9].each_stub_opponents([players[4]])
          end

          it "redoes the pairing of the descended players" do
            bracket.pair_numbers.should == [[1, 3], [2, 5], [4, 8], [6, 9], [7, 10]]
          end
        end

        context "no moved down players can't be paired" do
          before(:each) do
            players[0..1].each_stub_opponents(players[0..9])
            players[2..9].each_stub_opponents(players[0..1])
          end

          it "moves those players down and pairs the rest" do
            bracket.pair_numbers.should == [[3, 7], [4, 8], [5, 9], [6, 10]]
            bracket.leftover_numbers.should == [1, 2]
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..11) }

        before(:each) do
          players[0].stub(points: 1.5)
          players[1].stub(points: 1.5)
        end

        context "one of the descended players can't be paired" do
          before(:each) do
            players[0].stub_opponents(players[1..10])
            players[1..10].each_stub_opponents([players[0]])
          end

          it "pairs the rest of the players" do
            bracket.pair_numbers.should == [[2, 3], [4, 8], [5, 9], [6, 10], [7, 11]]
          end

          it "downfloats the descended player" do
            bracket.leftover_numbers.should == [1]
          end
        end

        context "same possible opponent for two moved down players" do
          before(:each) do
            players[0..1].each_stub_opponents(players[0..9])
            players[2..9].each_stub_opponents(players[0..1])
          end

          it "downfloats the lower player and pairs the rest" do
            bracket.pair_numbers.should == [[1, 11], [3, 7], [4, 8], [5, 9], [6, 10]]
            bracket.leftover_numbers.should == [2]
          end

          context "the lower player has already downfloated" do
            before(:each) do
              players[1].stub(floats: [:down])
            end

            it "downfloats the higher player" do
              bracket.pair_numbers.should == [[2, 11], [3, 7], [4, 8], [5, 9], [6, 10]]
              bracket.leftover_numbers.should == [1]
            end

            context "the higher player has more points" do
              before(:each) { players[0].stub(points: 3) }

              it "gives priority to the player with more points (C.6)" do
                bracket.pair_numbers.should == [[1, 11], [3, 7], [4, 8], [5, 9], [6, 10]]
                bracket.leftover_numbers.should == [2]
              end
            end
          end
        end

        context "the lowest player has already downfloated" do
          before(:each) { players[10].stub(floats: [:down]) }

          it "downfloats a different player" do
            bracket.leftover_numbers.should == [10]
            bracket.pair_numbers.should == [[1, 3], [2, 4], [5, 8], [6, 9], [7, 11]]
          end
        end

        context "all players have downfloated except the highest S2 one" do
          before(:each) do
            players[3..10].each_stub(floats: [:down])
          end

          it "downfloats that player" do
            bracket.leftover_numbers.should == [3]
            bracket.pair_numbers.should == [[1, 4], [2, 5], [6, 9], [7, 10], [8, 11]]
          end
        end

        context "all players in S2 have downfloated" do
          before(:each) do
            players[2..10].each_stub(floats: [:down])
          end

          it "downfloats the lowest player" do
            bracket.leftover_numbers.should == [11]
            bracket.pair_numbers.should == [[1, 3], [2, 4], [5, 8], [6, 9], [7, 10]]
          end
        end

        context "moved down players have different points" do
          before(:each) do
            players[0..1].each_stub(points: 3)
            players[2..3].each_stub(points: 2)
          end

          context "three downfloats needed" do
            before(:each) do
              players[0..3].each_stub_opponents(players - [players[4]])
              players[5..9].each_stub_opponents(players[0..3])
            end

            context "only a player with less points didn't downfloat" do
              before(:each) do
                players[0..2].each_stub(floats: [:down])
              end

              it "pairs the first player" do
                bracket.pair_numbers.should == [[1, 5], [6, 9], [7, 10], [8, 11]]
              end
            end

            context "the second player downfloated" do
              before(:each) do
                players[1].stub(floats: [:down])
              end

              it "pairs the second player" do
                bracket.pair_numbers.should == [[2, 5], [6, 9], [7, 10], [8, 11]]
              end
            end
          end
        end
      end

      context "half of the players are moved down players" do
        let(:players) { create_players(1..10) }

        before(:each) do
          players[0..4].each_stub(points: 1.5)
          players[5..9].each_stub(points: 1)
        end

        it "pairs the bracket like a homogeneous bracket" do
          bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
        end

        context "one of the players can't be paired" do
          before(:each) do
            players[0].stub_opponents(players[1..9])
            players[1..9].each_stub_opponents([players[0]])
          end

          it "doesn't pair that player" do
            bracket.pair_numbers.should == [[2, 6], [3, 7], [4, 8], [5, 9]]
          end

          it "moves that player and the last player down" do
            bracket.leftover_numbers.should == [1, 10]
          end
        end
      end

      context "more than half the players moved down players" do
        let(:players) { create_players(1..12) }

        before(:each) do
          players[0..7].each_stub(points: 1.5)
          players[8..11].each_stub(points: 1)
        end

        context "the first four moved down player can't be paired" do
          before(:each) do
            players[0..3].each_stub_opponents(players[0..11])
            players[4..11].each_stub_opponents(players[0..3])
          end

          it "moves those players down and pairs the rest" do
            bracket.pair_numbers.should == [[5, 9], [6, 10], [7, 11], [8, 12]]
            bracket.leftover_numbers.should == [1, 2, 3, 4]
          end
        end
      end
    end
  end
end
