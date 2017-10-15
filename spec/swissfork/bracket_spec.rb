require "spec_helper"
require "swissfork/bracket"
require "swissfork/player"

module Swissfork
  describe Bracket do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:bracket) { Bracket.for(players) }

    describe "#numbers" do
      let(:players) { create_players(1..6) }

      it "returns the numbers for the players in the bracket" do
        bracket.numbers.should == [1, 2, 3, 4, 5, 6]
      end
    end

    describe "#homogeneous?" do
      let(:players) { create_players(1..6) }

      before(:each) do
        players.each { |player| player.stub(points: 1) }
      end

      context "players with the same points" do
        it "returns true" do
          bracket.homogeneous?.should be true
        end
      end

      context "players with different number of points" do
        before(:each) do
          players.first.stub(points: 1.5)
        end

        it "returns false" do
          bracket.homogeneous?.should be false
        end
      end

      context "at least half of the players have different number of points" do
        before(:each) do
          players[0..2].each { |player| player.stub(points: 1.5) }
        end

        it "returns false" do
          bracket.homogeneous?.should be false
        end
      end
    end

    describe "#maximum_number_of_pairs" do
      context "even number of players" do
        let(:players) { create_players(1..6) }

        it "returns half of the number of players" do
          bracket.maximum_number_of_pairs.should == 3
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..7) }

        it "returns half of the number of players rounded downwards" do
          bracket.maximum_number_of_pairs.should == 3
        end
      end
    end

    describe "#points" do
      let(:players) { create_players(1..6) }

      before(:each) do
        players.each { |player| player.stub(points: 1) }
      end

      context "homogeneous bracket" do
        it "returns the number of points from all players" do
          bracket.points.should == 1
        end
      end

      context "heterogeneous bracket" do
        before(:each) { players.last.stub(points: 0.5) }

        it "returns the points from the player with the lowest amount of points" do
          bracket.points.should == 0.5
        end
      end
    end

    describe "#number_of_moved_down_players" do
      let(:players) { create_players(1..6) }

      before(:each) do
        players.each { |player| player.stub(points: 1) }
      end

      context "homogeneous bracket" do
        it "returns zero" do
          bracket.number_of_moved_down_players.should == 0
        end
      end

      context "heterogeneous bracket" do
        before(:each) { players.first.stub(points: 1.5) }

        it "returns the number of descended players" do
          bracket.number_of_moved_down_players.should == 1
        end
      end
    end

    describe "#number_of_possible_pairs" do
      let(:players) { create_players(1..6) }

      context "all players can be paired" do
        it "returns half of the total number of players" do
          bracket.number_of_possible_pairs.should == 3
        end

        context "odd number of players" do
          let(:players) { create_players(1..7) }

          it "returns half of the total number of players, rounding down" do
            bracket.number_of_possible_pairs.should == 3
          end
        end
      end

      context "some players can't be paired" do
        before(:each) do
          players[0].stub_opponents(players[1..5])
          players[1..5].each { |player| player.stub_opponents([players[0]]) }
        end

        it "returns half of the number of pairable players, rounding down" do
          bracket.number_of_possible_pairs.should == 2
        end
      end

      context "two players can only be paired to the same opponent" do
        before(:each) do
          players[0..1].each { |player| player.stub_opponents(players[0..4]) }
          players[2..4].each { |player| player.stub_opponents(players[0..1]) }
        end

        it "counts only one of those players as pairable" do
          bracket.number_of_possible_pairs.should == 2
        end
      end

      context "five players can only be paired to the same opponent" do
        before(:each) do
          players[0..4].each { |player| player.stub_opponents(players[0..4]) }
        end

        it "counts only one of those players as pairable" do
          bracket.number_of_possible_pairs.should == 1
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
          bracket.number_of_possible_pairs.should == 3
        end

        context "one of the players can also be paired to another one" do
          before(:each) do
            players[2].stub_opponents(players[0..2] + players[6..7])
            players[3].stub_opponents(players[0..1])
          end

          it "counts all players as pairable" do
            bracket.number_of_possible_pairs.should == 4
          end
        end
      end
    end

    describe "#number_of_moved_down_possible_pairs" do
      let(:players) { create_players(1..10) }

      before(:each) do
        players[0..2].each { |player| player.stub(points: 1.5) }
        players[3..9].each { |player| player.stub(points: 1) }
      end

      context "all moved down players can be paired" do
        before(:each) do
          players[0].stub_opponents(players[1..2])
          players[1].stub_opponents([players[0], players[2]])
          players[2].stub_opponents(players[0..1])
        end

        it "returns the number of moved down players" do
          bracket.number_of_moved_down_possible_pairs.should == 3
        end
      end

      context "there are more moved down players than resident players" do
        let(:players) { create_players(1..5) }

        before(:each) do
          players[0..2].each { |player| player.stub(points: 1.5) }
          players[3..4].each { |player| player.stub(points: 1) }
          players[0].stub_opponents(players[1..2])
          players[1].stub_opponents([players[0], players[2]])
          players[2].stub_opponents(players[0..1])
        end

        it "returns the number of resident players" do
          bracket.number_of_moved_down_possible_pairs.should == 2
        end
      end

      context "one of the moved down players can't be paired" do
        before(:each) do
          players[0].stub_opponents(players[1..9])
          players[1].stub_opponents([players[0], players[2]])
          players[2].stub_opponents(players[0..1])
          players[3..9].each { |player| player.stub_opponents([players[0]]) }
        end

        it "doesn't count that player as pairable" do
          bracket.number_of_moved_down_possible_pairs.should == 2
        end
      end

      context "two of the moved down players can't be paired" do
        before(:each) do
          players[0..1].each { |player| player.stub_opponents(players[0..9]) }
          players[2].stub_opponents(players[0..1])
          players[3..9].each { |player| player.stub_opponents(players[0..1]) }
        end

        it "doesn't count those players as pairable" do
          bracket.number_of_moved_down_possible_pairs.should == 1
        end
      end

      context "two players can only be paired to the same opponent" do
        before(:each) do
          players[0..1].each { |player| player.stub_opponents(players[0..8]) }
          players[2].stub_opponents(players[0..1])
          players[3..8].each { |player| player.stub_opponents(players[0..1]) }
        end

        it "counts only one of those players as pairable" do
          bracket.number_of_moved_down_possible_pairs.should == 2
        end
      end

      context "three players can only be paired to the same two opponents" do
        let(:players) { create_players(1..8) }

        before(:each) do
          players[0..2].each { |player| player.stub_opponents(players[0..7]) }
          players[3..7].each { |player| player.stub_opponents(players[0..2]) }
        end

        it "counts only two of those players as pairable" do
          bracket.number_of_possible_pairs.should == 2
        end
      end
    end

    describe "#s1_numbers" do
      let(:bracket) do
        Bracket.for([]).tap do |bracket|
          bracket.stub(s1: create_players(1..4))
        end
      end

      it "returns the numbers for the players in s1" do
        bracket.s1_numbers.should == [1, 2, 3, 4]
      end
    end

    describe "#s2_numbers" do
      let(:bracket) do
        Bracket.for([]).tap do |bracket|
          bracket.stub(s2: create_players(5..8))
        end
      end

      it "returns the numbers for the players in s1" do
        bracket.s2_numbers.should == [5, 6, 7, 8]
      end
    end

    describe "#s1" do
      context "even number of players" do
        let(:players) { create_players(1..6) }
        before(:each) do
          players.each { |player| player.stub(points: 1) }
        end

        context "homogeneous bracket" do
          it "returns the first half of the players" do
            bracket.s1_numbers.should == [1, 2, 3]
          end
        end

        context "heterogeneous bracket" do
          before(:each) do
            players[0..1].each { |player| player.stub(points: 1.5) }
          end

          it "returns the descended players" do
            bracket.s1_numbers.should == [1, 2]
          end
        end

        context "unordered players" do
          let(:players) { create_players(1..6).shuffle }

          it "orders the players" do
            bracket.s1_numbers.should == [1, 2, 3]
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..7) }

        it "returns the first half of the players, rounded downwards" do
          bracket.s1_numbers.should == [1, 2, 3]
        end
      end
    end

    describe "#s2" do
      context "even number of players" do
        let(:players) { create_players(1..6) }

        before(:each) do
          players.each { |player| player.stub(points: 1) }
        end

        context "homogeneous bracket" do
          it "returns the second half of the players" do
            bracket.s2_numbers.should == [4, 5, 6]
          end
        end

        context "heterogeneous bracket" do
          before(:each) do
            players[0..1].each { |player| player.stub(points: 1.5) }
          end

          it "returns all players but the descended ones" do
            bracket.s2_numbers.should == [3, 4, 5, 6]
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..7) }

        it "returns the second half of the players, rounded upwards" do
          bracket.s2_numbers.should == [4, 5, 6, 7]
        end
      end
    end

    describe "#exchange" do
      let(:s1_players) { create_players(1..5) }
      let(:s2_players) { create_players(6..11) }
      let(:bracket) { Bracket.for(s1_players + s2_players) }

      context "two exchanges" do
        before(:each) { 2.times { bracket.exchange }}

        it "exchanges the players and reorders S1" do
          bracket.s1_numbers.should == [1, 2, 3, 4, 7]
        end
      end

      context "heterogeneous bracket" do
        before(:each) do
          s1_players[0..2].each { |player| player.stub(points: 2) }
          bracket.stub(number_of_required_moved_down_pairs: 2)
        end

        context "two exchanges" do
          before(:each) { 2.times { bracket.exchange }}

          it "exchanges players and reorders S1 and Limbo" do
            bracket.s1_numbers.should == [2, 3]
            bracket.limbo_numbers.should == [1]
            bracket.s2_numbers.should == [4, 5, 6, 7, 8, 9, 10, 11]
          end
        end
      end
    end

    describe "#pair_numbers" do
      context "even number of players" do
        let(:players) { create_players(1..10) }
        before(:each) do
          players.each { |player| player.stub_opponents([]) }
        end

        context "no previous opponents" do
          it "pairs the players from s1 with the players from s2" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
          end
        end

        context "need to transpose once" do
          before(:each) do
            players[4].stub_opponents([players[9]])
            players[9].stub_opponents([players[4]])
          end

          it "pairs the players after transposing" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 10], [5, 9]]
          end
        end

        context "need to transpose twice" do
          before(:each) do
            players[3].stub_opponents([players[9], players[8]])
            players[9].stub_opponents([players[3]])
            players[8].stub_opponents([players[3]])
          end

          it "pairs using the next transposition" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 9], [4, 8], [5, 10]]
          end
        end

        context "need to transpose three times" do
          before(:each) do
            players[3].stub_opponents([players[8]])
            players[4].stub_opponents(players[8..9])
            players[9].stub_opponents([players[4]])
            players[8].stub_opponents(players[3..4])
          end

          it "pairs using the next transposition" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 9], [4, 10], [5, 8]]
          end
        end

        context "only the last transposition makes pairing possible" do
          before(:each) do
            players[4].stub_opponents(players[6..9])
            players[3].stub_opponents(players[7..9])
            players[2].stub_opponents(players[8..9])
            players[1].stub_opponents([players[9]])

            players[9].stub_opponents(players[1..4])
            players[8].stub_opponents(players[2..4])
            players[7].stub_opponents(players[3..4])
            players[6].stub_opponents([players[4]])
          end

          it "pairs after transposing every player" do
            bracket.pair_numbers.should == [[1, 10], [2, 9], [3, 8], [4, 7], [5, 6]]
          end
        end

        context "one previous opponent" do
          before(:each) do
            players[0].stub_opponents([players[5]])
            players[5].stub_opponents([players[0]])
            players[3].stub_opponents([players[8]])
            players[8].stub_opponents([players[3]])
          end

          it "pairs the players avoiding previous opponents" do
            bracket.pair_numbers.should == [[1, 7], [2, 6], [3, 8], [4, 10], [5, 9]]
          end
        end

        context "several previous opponents" do
          before(:each) do
            players[2].stub_opponents([players[9]])
            players[3].stub_opponents(players[8..9])
            players[4].stub_opponents(players[7..9])

            players[9].stub_opponents(players[2..4])
            players[8].stub_opponents(players[3..4])
            players[7].stub_opponents([players[4]])
          end

          it "pairs the players avoiding previous opponents" do
            bracket.pair_numbers.should == [[1, 6], [2, 10], [3, 9], [4, 8], [5, 7]]
          end
        end

        context "one player from S1 has played against everyone in S2" do
          before(:each) do
            players[0].stub_opponents(players[5..9])
            players[5..9].each { |player| player.stub_opponents([players[0]]) }
          end

          it "pairs the players with another player from S1" do
            bracket.pair_numbers.should == [[1, 5], [2, 7], [3, 8], [4, 9], [6, 10]]
          end
        end

        context "two players from S1 have played against everyone in S2" do
          before(:each) do
            players[0].stub_opponents([players[1]] + players[3..9])
            players[1].stub_opponents(players[0..2] + players[4..9])
            players[2].stub_opponents([players[1]])
            players[3].stub_opponents([players[0]])
            players[4..9].each { |player| player.stub_opponents([players[0], players[1]]) }
          end

          it "pairs those two players with players from S1" do
            bracket.pair_numbers.should == [[1, 3], [2, 4], [5, 8], [6, 9], [7, 10]]
          end
        end

        context "one of the players can't be paired" do
          before(:each) do
            players[0].stub_opponents(players[1..9])
            players[1..9].each { |player| player.stub_opponents([players[0]]) }
          end

          it "doesn't pair that player" do
            bracket.pair_numbers.should == [[2, 6], [3, 7], [4, 8], [5, 9]]
          end

          it "moves that player and the last player down" do
            bracket.leftover_numbers.should == [1, 10]
          end
        end

        context "two players can only play against one opponent" do
          before(:each) do
            players[0..1].each { |player| player.stub_opponents(players[0..8]) }
            players[2..8].each { |player| player.stub_opponents([players[0], players[1]]) }
          end

          it "pairs the higher of those two players" do
            bracket.pair_numbers.should == [[1, 10], [3, 6], [4, 7], [5, 8]]
          end

          it "moves the lower player and the last player down" do
            bracket.leftover_numbers.should == [2, 9]
          end

          context "the lower player has already downfloated" do
            before(:each) do
              players[1].stub(floats: [:down])
            end

            it "pairs the lower player, and moves the higher one down" do
              bracket.pair_numbers.should == [[2, 10], [3, 6], [4, 7], [5, 8]]
              bracket.leftover_numbers.should == [1, 9]
            end
          end
        end

        context "four players can only play against one opponent" do
          before(:each) do
            players[0..3].each { |player| player.stub_opponents(players[0..5] + players[7..9]) }
            players[4..5].each { |player| player.stub_opponents(players[0..3]) }
            players[7..9].each { |player| player.stub_opponents(players[0..3]) }
          end

          it "downfloats four players" do
            bracket.pair_numbers.should == [[1, 7], [5, 8], [6, 9]]
            bracket.leftover_numbers.should == [2, 3, 4, 10]
          end

          context "two of those players and the last one have already downfloated" do
            before(:each) do
              players[0..1].each { |player| player.stub(floats: [:down]) }
              players[9].stub(floats: [:down])
            end

            it "minimizes same downfloats as the previous round (minimum: 2)" do
              bracket.pair_numbers.should == [[1, 7], [5, 8], [6, 10]]
              bracket.leftover_numbers.should == [2, 3, 4, 9]
            end

            context "the penultimate downfloated two rounds ago" do
              before(:each) do
                players[8].stub(floats: [:down, nil])
              end

              it "minimizes same downfloats as two rounds before (minimum: 0)" do
                bracket.pair_numbers.should == [[1, 7], [5, 9], [6, 10]]
                bracket.leftover_numbers.should == [2, 3, 4, 8]
              end

              context "one of the required downfloats also descended 2 rounds ago" do
                before(:each) do
                  players[3].stub(floats: [:down, nil])
                end

                it "minimizes same downfloats as two rounds before (minimum: 1)" do
                  bracket.pair_numbers.should == [[1, 7], [5, 9], [6, 10]]
                  bracket.leftover_numbers.should == [2, 3, 4, 8]
                end
              end
            end
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..11) }
        before(:each) do
          players.each { |player| player.stub_opponents([]) }
        end

        context "no previous opponents" do
          it "pairs all players except the last one" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
          end
        end

        context "previous opponents affecting the second to last player" do
          before(:each) do
            players[4].stub_opponents([players[9]])
            players[9].stub_opponents([players[4]])
          end

          it "pairs all players except the second to last one" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 11]]
          end
        end

        context "all players downfloated; the first one did so 2 rounds ago" do
          before(:each) do
            players[0].stub(floats: [:down, nil])
            players[1..10].each { |player| player.stub(floats: [nil, :down]) }
          end

          it "downfloats that player and pairs the rest in order" do
            bracket.pair_numbers.should == [[2, 7], [3, 8], [4, 9], [5, 10], [6, 11]]
          end
        end
      end

      context "heterogeneous groups" do
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
            players[5..9].each { |player| player.stub_opponents([players[4]]) }
          end

          it "redoes the pairing of the descended players" do
            bracket.pair_numbers.should == [[1, 3], [2, 5], [4, 8], [6, 9], [7, 10]]
          end
        end

        context "no moved down players can't be paired" do
          before(:each) do
            players[0..1].each { |player| player.stub_opponents(players[0..9]) }
            players[2..9].each { |player| player.stub_opponents(players[0..1]) }
          end

          it "moves those players down and pairs the rest" do
            bracket.pair_numbers.should == [[3, 7], [4, 8], [5, 9], [6, 10]]
            bracket.leftover_numbers.should == [1, 2]
          end
        end
      end

      context "heterogeneous groups with odd number of players" do
        let(:players) { create_players(1..11) }

        before(:each) do
          players[0].stub(points: 1.5)
          players[1].stub(points: 1.5)
        end

        context "one of the descended players can't be paired" do
          before(:each) do
            players[0].stub_opponents(players[1..10])
            players[1..10].each { |player| player.stub_opponents([players[0]]) }
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
            players[0..1].each { |player| player.stub_opponents(players[0..9]) }
            players[2..9].each { |player| player.stub_opponents(players[0..1]) }
          end

          it "downfloats the lower player and pairs the rest" do
            bracket.pair_numbers.should == [[1, 11], [3, 7], [4, 8], [5, 9], [6, 10]]
            bracket.leftover_numbers.should == [2]
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
            players[3..10].each { |player| player.stub(floats: [:down]) }
          end

          it "downfloats that player" do
            bracket.leftover_numbers.should == [3]
            bracket.pair_numbers.should == [[1, 4], [2, 5], [6, 9], [7, 10], [8, 11]]
          end
        end

        context "all players in S2 have downfloated" do
          before(:each) do
            players[2..10].each { |player| player.stub(floats: [:down]) }
          end

          it "downfloats the lowest player" do
            bracket.leftover_numbers.should == [11]
            bracket.pair_numbers.should == [[1, 3], [2, 4], [5, 8], [6, 9], [7, 10]]
          end
        end
      end

      context "heterogeneous groups with half of the players having more points" do
        let(:players) { create_players(1..10) }

        before(:each) do
          players[0..4].each { |player| player.stub(points: 1.5) }
          players[5..9].each { |player| player.stub(points: 1) }
        end

        it "pairs the bracket like a homogeneous bracket" do
          bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
        end

        context "one of the players can't be paired" do
          before(:each) do
            players[0].stub_opponents(players[1..9])
            players[1..9].each { |player| player.stub_opponents([players[0]]) }
          end

          it "doesn't pair that player" do
            bracket.pair_numbers.should == [[2, 6], [3, 7], [4, 8], [5, 9]]
          end

          it "moves that player and the last player down" do
            bracket.leftover_numbers.should == [1, 10]
          end
        end
      end

      context "heterogeneous bracket with more than half moved down players" do
        let(:players) { create_players(1..12) }

        before(:each) do
          players[0..7].each { |player| player.stub(points: 1.5) }
          players[8..11].each { |player| player.stub(points: 1) }
        end

        context "the first four moved down player can't be paired" do
          before(:each) do
            players[0..3].each { |player| player.stub_opponents(players[0..11]) }
            players[4..11].each { |player| player.stub_opponents(players[0..3]) }
          end

          it "moves those players down and pairs the rest" do
            bracket.pair_numbers.should == [[5, 9], [6, 10], [7, 11], [8, 12]]
            bracket.leftover_numbers.should == [1, 2, 3, 4]
          end
        end
      end
    end

    describe "#leftovers" do
      context "even number of players" do
        let(:players) { create_players(1..10) }

        it "returns an empty array" do
          bracket.leftovers.should == []
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..11) }

        context "no previous opponents" do
          it "returns the last player" do
            bracket.leftover_numbers.should == [11]
          end
        end

        context "previous opponents affecting the second to last player" do
          before(:each) do
            players[4].stub_opponents([players[9]])
            players[9].stub_opponents([players[4]])
          end

          it "returns the second to last player" do
            bracket.leftover_numbers.should == [10]
          end
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
            bracket.bye_can_be_selected?.should be true
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
              bracket.bye_can_be_selected?.should be true
            end
          end

          context "pairing incompatibilities" do
            before(:each) do
              players[0].stub_opponents(players[1..5])
              players[1..5].each { |player| player.stub_opponents([players[0]]) }
            end

            it "returns false" do
              bracket.bye_can_be_selected?.should be false
            end
          end
        end

        context "all players had byes" do
          before(:each) do
            players[0..6].each { |player| player.stub(had_bye?: true) }
          end

          it "returns true" do
            bracket.bye_can_be_selected?.should be false
          end
        end
      end
    end

    describe "methods differing between homogeneous and heterogeneous brackets" do
      let(:bracket) { Bracket.new(players) }
      let(:players) { create_players(1..10) }

      it "raises an exception when called directly from Bracket" do
        lambda { bracket.s2 }.should raise_error("Implement in subclass")
        lambda { bracket.number_of_required_pairs }.should raise_error("Implement in subclass")
        lambda { bracket.exchange }.should raise_error("Implement in subclass")
      end
    end

    describe "#all_players_can_be_paired?" do
      let(:players) { create_players(1..12) }
      let(:bracket) { Bracket.for(players) }

      context "pairable bracket" do
        it "returns true" do
          bracket.all_players_can_be_paired?.should be true
        end
      end

      context "existing opponents still make the bracket pairable" do
        before(:each) do
          players[11].stub_opponents(players[6..10])
          players[6..10].each { |player| player.stub_opponents([players[11]]) }
        end

        it "returns true" do
          bracket.all_players_can_be_paired?.should be true
        end
      end

      context "completely unpairable bracket" do
        before(:each) do
          players[0..11].each { |player| player.stub_opponents(players[0..11]) }
        end

        it "returns false" do
          bracket.all_players_can_be_paired?.should be false
        end
      end

      context "one player can't be paired at all" do
        before(:each) do
          players[11].stub_opponents(players[0..10])
          players[0..10].each { |player| player.stub_opponents([players[11]]) }
        end

        it "returns false" do
          bracket.all_players_can_be_paired?.should be false
        end
      end

      context "two players have the same possible opponent" do
        before(:each) do
          players[10..11].each { |player| player.stub_opponents(players[1..11]) }
          players[1..9].each { |player| player.stub_opponents(players[10..11]) }
        end

        it "returns false" do
          bracket.all_players_can_be_paired?.should be false
        end
      end
    end

    describe "<=>" do
      def bracket_with_points(points)
        Bracket.for([]).tap do |bracket|
          bracket.stub(points: points)
        end
      end

      let(:higher_bracket) { bracket_with_points(3) }
      let(:medium_bracket) { bracket_with_points(2) }
      let(:lower_bracket) { bracket_with_points(1) }

      it "sorts brackets based on points in descending order" do
        [medium_bracket, lower_bracket, higher_bracket].sort.should ==
          [higher_bracket, medium_bracket, lower_bracket]
      end
    end
  end
end
