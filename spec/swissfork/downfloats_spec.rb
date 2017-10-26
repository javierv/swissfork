require "spec_helper"
require "swissfork/round"
require "swissfork/player"

module Swissfork
  describe Round do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:round) { Round.new(players) }

    describe "#pairs requiring downfloats" do
      context "many brackets, the first one having descendent players" do
        let(:players) { create_players(1..10) }

        before(:each) do
          players[0..4].each { |player| player.stub(points: 1) }
        end

        it "pairs the moved down player on the second bracket" do
          round.pair_numbers.should == [[1, 3], [2, 4], [5, 6], [7, 9], [8, 10]]
        end

        context "the last player can't descend" do
          before(:each) do
            players[4].stub_opponents(players[5..9])
            players[5..9].each { |player| player.stub_opponents([players[4]]) }
          end

          it "descends the second to last player" do
            round.pair_numbers.should == [[1, 3], [2, 5], [4, 6], [7, 9], [8, 10]]
          end
        end

        context "the last player descended in the previous round" do
          before(:each) do
            players[4].stub(floats: [nil, nil, :down])
          end

          it "descends the second to last player" do
            round.pair_numbers.should == [[1, 3], [2, 5], [4, 6], [7, 9], [8, 10]]
          end
        end

        context "the first player ascended in the previous round" do
          before(:each) do
            players[5].stub(floats: [nil, nil, :up])
          end

          it "ascends the second player" do
            round.pair_numbers.should == [[1, 3], [2, 4], [5, 7], [6, 9], [8, 10]]
          end
        end

        context "the last player descended two rounds ago" do
          before(:each) do
            players[4].stub(floats: [nil, nil, :down, nil])
          end

          it "descends the second to last player" do
            round.pair_numbers.should == [[1, 3], [2, 5], [4, 6], [7, 9], [8, 10]]
          end
        end

        context "the first player ascended two rounds ago" do
          before(:each) do
            players[5].stub(floats: [nil, nil, :up, nil])
          end

          it "ascends the second player" do
            round.pair_numbers.should == [[1, 3], [2, 4], [5, 7], [6, 9], [8, 10]]
          end
        end

        context "all players in S2 descended in the previous round" do
          before(:each) do
            players[2..4].each { |player| player.stub(floats: [:down]) }
          end

          context "homogeneous group" do
            it "descends the last player from S1" do
              round.pair_numbers.should == [[1, 4], [3, 5], [2, 6], [7, 9], [8, 10]]
            end
          end

          context "heterogeneous group" do
            before(:each) do
              players[0..1].each { |player| player.stub(points: 2) }
              players[0].stub_opponents([players[1]])
              players[1].stub_opponents([players[0]])
            end

            it "descends the last player from S2" do
              round.pair_numbers.should == [[1, 3], [2, 4], [5, 6], [7, 9], [8, 10]]
            end
          end
        end
      end

      context "many brackets, the first one being impossible to pair at all" do
        let(:players) { create_players(1..10) }

        before(:each) do
          players[0..1].each { |player| player.stub(points: 1) }
          players[2..9].each { |player| player.stub(points: 0) }
          players[0].stub_opponents([players[1]])
          players[1].stub_opponents([players[0]])
        end

        it "descends all players to the next bracket" do
          round.pair_numbers.should == [[1, 3], [2, 4], [5, 8], [6, 9], [7, 10]]
        end
      end

      context "many brackets, the first one having unpairable players" do
        let(:players) { create_players(1..10) }

        before(:each) do
          players[0..3].each { |player| player.stub(points: 1) }
          players[4..9].each { |player| player.stub(points: 0) }
          players[0..1].each { |player| player.stub_opponents([players[2], players[3]]) }
          players[2].stub_opponents([players[0], players[1], players[3]])
          players[3].stub_opponents([players[0], players[1], players[2]])
        end

        it "descends the unpairable players to the next bracket" do
          round.pair_numbers.should == [[1, 2], [3, 5], [4, 6], [7, 9], [8, 10]]
        end
      end

      context "a player is required to downfloat twice" do
        let(:players) { create_players(1..10) }

        before(:each) do
          players[0..2].each { |player| player.stub(points: 2) }
          players[3..6].each { |player| player.stub(points: 1) }
          players[7..9].each { |player| player.stub(points: 0) }
          players[0].stub_opponents(players[1..6])
          players[1..6].each { |player| player.stub_opponents([players[0]]) }
        end

        it "downfloats the unpairable player twice" do
          round.pair_numbers.should == [[2, 3], [1, 8], [4, 6], [5, 7], [9, 10]]
        end
      end

      context "PPB with 3 moved down players, requiring 2 players to downfloat" do
        let(:players) { create_players(1..10) }

        before(:each) do
          players[0..2].each { |player| player.stub(points: 2) }
          players[3..5].each { |player| player.stub(points: 1) }
          players[6..9].each { |player| player.stub(points: 0) }

          # We need to downfloat two players, but if we downfloat two resident
          # players, the moved down players can't be paired
          players[0].stub_opponents(players[1..2])
          players[1].stub_opponents([players[0], players[2]])
          players[2].stub_opponents(players[0..1])
          players[9].stub_opponents(players[6..8])
          players[6..8].each { |player| player.stub_opponents([players[9]]) }
        end

        it "downfloats one moved down player and one resident player" do
          round.pair_numbers.should == [[1, 4], [2, 5], [3, 7], [6, 10], [8, 9]]
        end

        context "no resident players can downfloat" do
          before(:each) do
            players[8..9].each { |player| player.stub_opponents(players[3..9]) }
            players[3..7].each { |player| player.stub_opponents(players[8..9]) }
          end

          it "downfloats two moved down players" do
            round.pair_numbers.should == [[1, 4], [2, 9], [3, 10], [5, 6], [7, 8]]
          end
        end
      end

      context "the first two brackets can't be paired" do
        let(:players) { create_players(1..10) }

        before(:each) do
          players[0..1].each { |player| player.stub(points: 3) }
          players[2..3].each { |player| player.stub(points: 2) }
          players[4..9].each { |player| player.stub(points: 1) }

          players[0..3].each { |player| player.stub_opponents(players[0..3]) }
        end

        it "downfloats players from both brackets" do
          round.pair_numbers.should == [[1, 5], [2, 6], [3, 7], [4, 8], [9, 10]]
        end
      end
    end
  end
end
