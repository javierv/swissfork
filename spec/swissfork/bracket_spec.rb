require "swissfork/bracket"
require "swissfork/player"

module Swissfork
  describe Bracket do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    describe "#add_player" do
      let(:players) { create_players(1..6) }
      let(:bracket) { Bracket.new(players) }

      context "player is the lowest player" do
        let(:player) { Player.new(7) }

        it "adds the player to the bracket" do
          bracket.add_player(player)
          bracket.players.should == players + [player]
        end
      end

      context "player isn't the lowest player" do
        let(:player) { Player.new(0) }

        before(:each) do
          bracket.s1 # Access so it's already generated
          bracket.add_player(player)
        end

        it "sorts the players after adding the player" do
          bracket.players.should == [player] + players
        end

        it "redefines S1 and S2" do
          bracket.s1.should == [player] + players[0..1]
          bracket.s2.should == players[2..5]
        end
      end
    end

    describe "#numbers" do
      let(:players) { create_players(1..6) }
      let(:bracket) { Bracket.new(players) }

      it "returns the numbers for the players in the bracket" do
        bracket.numbers.should == [1, 2, 3, 4, 5, 6]
      end
    end

    describe "#homogeneous?" do
      let(:players) { create_players(1..6) }
      let(:bracket) { Bracket.new(players) }

      before(:each) do
        players.each { |player| player.stub(:points).and_return(1) }
      end

      context "players with the same points" do
        it "returns true" do
          bracket.homogeneous?.should be true
        end
      end

      context "players with different number of points" do
        before(:each) do
          players.first.stub(:points).and_return(1.5)
        end

        it "returns false" do
          bracket.homogeneous?.should be false
        end
      end

      context "at least half of the players have different number of points" do
        before(:each) do
          players[0..2].each { |player| player.stub(:points).and_return(1.5) }
        end

        it "returns true" do
          bracket.homogeneous?.should be true
        end
      end
    end

    describe "#heterogeneous?" do
      let(:players) { create_players(1..6) }
      let(:bracket) { Bracket.new(players) }

      before(:each) do
        players.each { |player| player.stub(:points).and_return(1) }
      end

      context "players with the same points" do
        it "returns false" do
          bracket.heterogeneous?.should be false
        end
      end

      context "players with different number of points" do
        before(:each) do
          players.first.stub(:points).and_return(1.5)
        end

        it "returns true" do
          bracket.heterogeneous?.should be true
        end
      end

      context "at least half of the players have different number of points" do
        before(:each) do
          players[0..2].each { |player| player.stub(:points).and_return(1.5) }
        end

        it "returns false" do
          bracket.heterogeneous?.should be false
        end
      end
    end

    describe "#maximum_number_of_pairs" do
      context "even number of players" do
        let(:players) { create_players(1..6) }
        let(:bracket) { Bracket.new(players) }

        it "returns half of the number of players" do
          bracket.maximum_number_of_pairs.should == 3
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..7) }
        let(:bracket) { Bracket.new(players) }

        it "returns half of the number of players rounded downwards" do
          bracket.maximum_number_of_pairs.should == 3
        end
      end
    end

    describe "#points" do
      let(:players) { create_players(1..6) }
      let(:bracket) { Bracket.new(players) }

      before(:each) do
        players.each { |player| player.stub(:points).and_return(1) }
      end

      context "homogeneous bracket" do
        it "returns the number of points from all players" do
          bracket.points.should == 1
        end
      end

      context "heterogeneous bracket" do
        before(:each) { players.last.stub(:points).and_return(0.5) }

        it "returns the points from the player with the lowest amount of points" do
          bracket.points.should == 0.5
        end
      end
    end

    describe "#number_of_descended_players" do
      let(:players) { create_players(1..6) }
      let(:bracket) { Bracket.new(players) }

      before(:each) do
        players.each { |player| player.stub(:points).and_return(1) }
      end

      context "homogeneous bracket" do
        it "returns zero" do
          bracket.number_of_descended_players.should == 0
        end
      end

      context "heterogeneous bracket" do
        before(:each) { players.first.stub(:points).and_return(1.5) }

        it "returns the number of descended players" do
          bracket.number_of_descended_players.should == 1
        end
      end
    end

    describe "#s1_numbers" do
      let(:bracket) do
        Bracket.new([]).tap do |bracket|
          bracket.stub(:s1).and_return(create_players(1..4))
        end
      end

      it "returns the numbers for the players in s1" do
        bracket.s1_numbers.should == [1, 2, 3, 4]
      end
    end

    describe "#s2_numbers" do
      let(:bracket) do
        Bracket.new([]).tap do |bracket|
          bracket.stub(:s2).and_return(create_players(5..8))
        end
      end

      it "returns the numbers for the players in s1" do
        bracket.s2_numbers.should == [5, 6, 7, 8]
      end
    end

    describe "#s1" do
      context "even number of players" do
        let(:players) { create_players(1..6) }
        let(:bracket) { Bracket.new(players) }
        before(:each) do
          players.each { |player| player.stub(:points).and_return(1) }
        end

        context "homogeneous bracket" do
          it "returns the first half of the players" do
            bracket.s1_numbers.should == [1, 2, 3]
          end
        end

        context "heterogeneous bracket" do
          before(:each) do
            players[0..1].each { |player| player.stub(:points).and_return(1.5) }
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
        let(:bracket) { Bracket.new(players) }

        it "returns the first half of the players, rounded downwards" do
          bracket.s1_numbers.should == [1, 2, 3]
        end
      end
    end

    describe "#s2" do
      context "even number of players" do
        let(:players) { create_players(1..6) }
        let(:bracket) { Bracket.new(players) }

        before(:each) do
          players.each { |player| player.stub(:points).and_return(1) }
        end

        context "homogeneous bracket" do
          it "returns the second half of the players" do
            bracket.s2_numbers.should == [4, 5, 6]
          end
        end

        context "heterogeneous bracket" do
          before(:each) do
            players[0..1].each { |player| player.stub(:points).and_return(1.5) }
          end

          it "returns all players but the descended ones" do
            bracket.s2_numbers.should == [3, 4, 5, 6]
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..7) }
        let(:bracket) { Bracket.new(players) }

        it "returns the second half of the players, rounded upwards" do
          bracket.s2_numbers.should == [4, 5, 6, 7]
        end
      end
    end

    describe "#exchange" do
      let(:s1_players) { create_players(1..5) }
      let(:s2_players) { create_players(6..11) }
      let(:bracket) { Bracket.new(s1_players + s2_players) }

      context "two exchanges" do
        before(:each) { 2.times { bracket.exchange }}

        it "exchanges the players and reorders S1 and S2" do
          bracket.s1_numbers.should == [1, 2, 3, 4, 7]
          bracket.s2_numbers.should == [5, 6, 8, 9, 10, 11]
        end
      end
    end

    describe "#pair_numbers" do
      context "even number of players" do
        let(:players) { create_players(1..10) }
        let(:bracket) { Bracket.new(players) }
        before(:each) do
          players.each { |player| player.stub(:opponents).and_return([]) }
        end

        context "no previous opponents" do
          it "pairs the players from s1 with the players from s2" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
          end
        end

        context "need to transpose once" do
          before(:each) do
            players[4].stub(:opponents).and_return([players[9]])
            players[9].stub(:opponents).and_return([players[4]])
          end

          it "pairs the players after transposing" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 10], [5, 9]]
          end
        end

        context "need to transpose twice" do
          before(:each) do
            players[3].stub(:opponents).and_return([players[9], players[8]])
            players[9].stub(:opponents).and_return([players[3]])
            players[8].stub(:opponents).and_return([players[3]])
          end

          it "pairs using the next transposition" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 9], [4, 8], [5, 10]]
          end
        end

        context "need to transpose three times" do
          before(:each) do
            players[3].stub(:opponents).and_return([players[8]])
            players[4].stub(:opponents).and_return(players[8..9])
            players[9].stub(:opponents).and_return([players[4]])
            players[8].stub(:opponents).and_return(players[3..4])
          end

          it "pairs using the next transposition" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 9], [4, 10], [5, 8]]
          end
        end

        context "only the last transposition makes pairing possible" do
          before(:each) do
            players[4].stub(:opponents).and_return(players[6..9])
            players[3].stub(:opponents).and_return(players[7..9])
            players[2].stub(:opponents).and_return(players[8..9])
            players[1].stub(:opponents).and_return([players[9]])

            players[9].stub(:opponents).and_return(players[1..4])
            players[8].stub(:opponents).and_return(players[2..4])
            players[7].stub(:opponents).and_return(players[3..4])
            players[6].stub(:opponents).and_return([players[4]])
          end

          it "pairs after transposing every player" do
            bracket.pair_numbers.should == [[1, 10], [2, 9], [3, 8], [4, 7], [5, 6]]
          end
        end

        context "one previous opponent" do
          before(:each) do
            players[0].stub(:opponents).and_return([players[5]])
            players[5].stub(:opponents).and_return([players[0]])
            players[3].stub(:opponents).and_return([players[8]])
            players[8].stub(:opponents).and_return([players[3]])
          end

          it "pairs the players avoiding previous opponents" do
            bracket.pair_numbers.should == [[1, 7], [2, 6], [3, 8], [4, 10], [5, 9]]
          end
        end

        context "several previous opponents" do
          before(:each) do
            players[2].stub(:opponents).and_return([players[9]])
            players[3].stub(:opponents).and_return(players[8..9])
            players[4].stub(:opponents).and_return(players[7..9])

            players[9].stub(:opponents).and_return(players[2..4])
            players[8].stub(:opponents).and_return(players[3..4])
            players[7].stub(:opponents).and_return([players[4]])
          end

          it "pairs the players avoiding previous opponents" do
            bracket.pair_numbers.should == [[1, 6], [2, 10], [3, 9], [4, 8], [5, 7]]
          end
        end

        context "one player from S1 has played against everyone in S2" do
          before(:each) do
            players[0].stub(:opponents).and_return(players[5..9])
            players[5..9].each { |player| player.stub(:opponents).and_return([players[0]]) }
          end

          it "pairs the players with another player from S1" do
            bracket.pair_numbers.should == [[1, 5], [2, 7], [3, 8], [4, 9], [6, 10]]
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..11) }
        let(:bracket) { Bracket.new(players) }
        before(:each) do
          players.each { |player| player.stub(:opponents).and_return([]) }
        end

        context "no previous opponents" do
          it "pairs all players except the last one" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
          end
        end

        context "previous opponents affecting the second to last player" do
          before(:each) do
            players[4].stub(:opponents).and_return([players[9]])
            players[9].stub(:opponents).and_return([players[4]])
          end

          it "pairs all players except the second to last one" do
            bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 11]]
          end
        end
      end

      context "heterogeneous groups" do
        let(:players) { create_players(1..10) }
        let(:bracket) { Bracket.new(players) }
        before(:each) do
          players[0].stub(:points).and_return(1.5)
          players[1].stub(:points).and_return(1.5)
        end

        context "the resulting homogeneous group is possible to pair" do
          it "pairs the descended players with the highest non-descended players" do
            bracket.pair_numbers.should == [[1, 3], [2, 4], [5, 8], [6, 9], [7, 10]]
          end
        end

        context "the resulting homogeneous group isn't possible to pair" do
          before(:each) do
            players[4].stub(:opponents).and_return(players[5..9])
            players[5..9].each do |player|
              player.stub(:opponents).and_return([players[4]])
            end
          end

          it "redoes the pairing of the descended players" do
            bracket.pair_numbers.should == [[1, 3], [2, 5], [4, 8], [6, 9], [7, 10]]
          end
        end
      end

      context "heterogeneous groups with odd number of players" do
        let(:players) { create_players(1..11) }
        let(:bracket) { Bracket.new(players) }

        before(:each) do
          players[0].stub(:points).and_return(1.5)
          players[1].stub(:points).and_return(1.5)
        end

        context "one of the descended players can't be paired" do
          before(:each) do
            players[0].stub(:opponents).and_return(players[1..10])
          end

          it "can't pair the bracket" do
            bracket.pairs.should be nil
          end
        end
      end
    end


    describe "#leftover_players" do
      context "even number of players" do
        let(:players) { create_players(1..10) }
        let(:bracket) { Bracket.new(players) }

        it "returns an empty array" do
          bracket.leftover_players.should == []
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..11) }
        let(:bracket) { Bracket.new(players) }

        context "no previous opponents" do
          it "returns the last player" do
            bracket.leftover_players.should == [players[10]]
          end
        end

        context "previous opponents affecting the second to last player" do
          before(:each) do
            players[4].stub(:opponents).and_return([players[9]])
            players[9].stub(:opponents).and_return([players[4]])
          end

          it "returns the second to last player" do
            bracket.leftover_players.should == [players[9]]
          end
        end
      end
    end

    describe "<=>" do
      def bracket_with_points(points)
        Bracket.new([]).tap do |bracket|
          bracket.stub(:points).and_return(points)
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
