require "swissfork/round"
require "swissfork/player"

module Swissfork
  describe Round do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    describe "#brackets" do
      context "players with the same points" do
        let(:players) { create_players(1..6) }

        it "returns only one bracket" do
          Round.new(players).brackets.count.should be 1
        end
      end

      context "players with different points" do
        let(:players) { create_players(1..6) }

        before(:each) do
          players[0].stub(:points).and_return(1)
          players[1].stub(:points).and_return(1)
          players[2].stub(:points).and_return(2)
          players[3].stub(:points).and_return(0.5)
        end

        let(:brackets) { Round.new(players).brackets }

        it "returns as many brackets as different points" do
          brackets.count.should be 4
        end

        it "sorts the bracket by number of points" do
          brackets.map(&:points).should == [2, 1, 0.5, 0]
        end

        it "groups each player to the right bracket" do
          brackets[0].players.should == [players[2]]
          brackets[1].players.should == [players[0], players[1]]
          brackets[2].players.should == [players[3]]
          brackets[3].players.should == [players[4], players[5]]
        end
      end
    end

    describe "#pairs" do
      let(:round) { Round.new(players) }

      context "only one bracket" do
        let(:players) { create_players(1..7) }

        it "returns the same pairs as the bracket" do
          round.pair_numbers.should == Bracket.new(players).pair_numbers
        end
      end

      context "many brackets, all easily paired" do
        let(:players) { create_players(1..20) }

        before(:each) do
          players[0..9].each { |player| player.stub(:points).and_return(1) }
        end

        it "returns the combination of each brackets pairs" do
          round.pair_numbers.should == Bracket.new(players[0..9]).pair_numbers + Bracket.new(players[10..19]).pair_numbers
        end
      end

      context "many brackets, the first one having descendent players" do
        let(:players) { create_players(1..10) }

        before(:each) do
          players[0..4].each { |player| player.stub(:points).and_return(1) }
        end

        it "pairs the descendent player on the second bracket" do
          round.pair_numbers.should == [[1, 3], [2, 4], [5, 6], [7, 9], [8, 10]]
        end

        context "the last player can't descend" do
          before(:each) do
            players[4].stub(:opponents).and_return(players[5..9])
            players[5..9].each do |player|
              player.stub(:opponents).and_return([players[4]])
            end
          end

          it "descends the second to last player" do
            round.pair_numbers.should == [[1, 3], [2, 5], [4, 6], [7, 9], [8, 10]]
          end
        end

        context "the last player descended in the previous round" do
          before(:each) do
            players[4].stub(:floats).and_return([nil, nil, :down])
          end

          it "descends the second to last player" do
            round.pair_numbers.should == [[1, 3], [2, 5], [4, 6], [7, 9], [8, 10]]
          end
        end

        context "the first player ascended in the previous round" do
          before(:each) do
            players[5].stub(:floats).and_return([nil, nil, :up])
          end

          it "ascends the second player" do
            round.pair_numbers.should == [[1, 3], [2, 4], [5, 7], [6, 9], [8, 10]]
          end
        end

        context "the last player descended two rounds ago" do
          before(:each) do
            players[4].stub(:floats).and_return([nil, nil, :down, nil])
          end

          it "descends the second to last player" do
            round.pair_numbers.should == [[1, 3], [2, 5], [4, 6], [7, 9], [8, 10]]
          end
        end

        context "the first player ascended two rounds ago" do
          before(:each) do
            players[5].stub(:floats).and_return([nil, nil, :up, nil])
          end

          it "ascends the second player" do
            round.pair_numbers.should == [[1, 3], [2, 4], [5, 7], [6, 9], [8, 10]]
          end
        end

        context "all players in S2 descended in the previous round" do
          before(:each) do
            players[2..4].each { |player| player.stub(:floats).and_return([:down]) }
          end

          context "homogeneous group" do
            it "descends the last player from S1" do
              round.pair_numbers.should == [[1, 4], [3, 5], [2, 6], [7, 9], [8, 10]]
            end
          end

          context "heterogeneous group" do
            before(:each) do
              players[0..1].each { |player| player.stub(:points).and_return(2) }
              players[0].stub(:opponents).and_return([players[1]])
              players[1].stub(:opponents).and_return([players[0]])
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
          players[0..1].each { |player| player.stub(:points).and_return(1) }
          players[2..9].each { |player| player.stub(:points).and_return(0) }
          players[0].stub(:opponents).and_return([players[1]])
          players[1].stub(:opponents).and_return([players[0]])
        end

        it "descends all players to the next bracket" do
          round.pair_numbers.should == [[1, 3], [2, 4], [5, 8], [6, 9], [7, 10]]
        end
      end

      context "many brackets, the first one having unpairable players" do
        let(:players) { create_players(1..10) }

        before(:each) do
          players[0..3].each { |player| player.stub(:points).and_return(1) }
          players[4..9].each { |player| player.stub(:points).and_return(0) }
          players[0..1].each { |player| player.stub(:opponents).and_return([players[2], players[3]]) }
          players[2].stub(:opponents).and_return([players[0], players[1], players[3]])
          players[3].stub(:opponents).and_return([players[0], players[1], players[2]])
        end

        it "descends the unpairable players to the next bracket" do
          round.pair_numbers.should == [[1, 2], [3, 5], [4, 6], [7, 9], [8, 10]]
        end
      end

      context "many brackets, the last one being impossible to pair" do
        let(:players) { create_players(1..10) }

        before(:each) do
          players[0..7].each { |player| player.stub(:points).and_return(1) }
          players[8..9].each { |player| player.stub(:points).and_return(0) }
          players[8].stub(:opponents).and_return([players[9]])
          players[9].stub(:opponents).and_return([players[8]])
        end

        it "descends players from the previous bracket" do
          round.pair_numbers.should == [[1, 4], [2, 5], [3, 6], [7, 9], [8, 10]]
        end
      end

      context "PPB has leftovers and last bracket has incompatible players" do
        let(:players) { create_players(1..11) }

        before(:each) do
          players[0..8].each { |player| player.stub(:points).and_return(1) }
          players[9..10].each { |player| player.stub(:points).and_return(0) }
          players[9].stub(:opponents).and_return([players[10]])
          players[10].stub(:opponents).and_return([players[9]])
        end

        it "pairs normally, using the leftovers " do
          round.pair_numbers.should == [[1, 5], [2, 6], [3, 7], [4, 8], [9, 10]]
        end
      end
    end
  end
end
