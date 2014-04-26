require "swissfork/bracket"

describe Swissfork::Bracket do
  def create_players(numbers)
    numbers.map { |number| Swissfork::Player.new(number) }
  end

  describe "#maximum_number_of_pairs" do
    context "even number of players" do
      let(:players) { create_players(1..6) }
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns half of the number of players" do
        bracket.maximum_number_of_pairs.should == 3
      end
    end

    context "odd number of players" do
      let(:players) { create_players(1..7) }
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns half of the number of players rounded downwards" do
        bracket.maximum_number_of_pairs.should == 3
      end
    end
  end

  describe "#numbers" do
    let(:players) { create_players(1..6) }
    let(:bracket) { Swissfork::Bracket.new(players) }

    it "returns the numbers for the players in the bracket" do
      bracket.numbers.should == [1, 2, 3, 4, 5, 6]
    end
  end

  describe "#s1_numbers" do
    let(:bracket) do
      Swissfork::Bracket.new([]).tap do |bracket|
        bracket.stub(:s1).and_return(create_players(1..4))
      end
    end

    it "returns the numbers for the players in s1" do
      bracket.s1_numbers.should == [1, 2, 3, 4]
    end
  end

  describe "#s2_numbers" do
    let(:bracket) do
      Swissfork::Bracket.new([]).tap do |bracket|
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
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns the first half of the players" do
        bracket.s1_numbers.should == [1, 2, 3]
      end
    end

    context "odd number of players" do
      let(:players) { create_players(1..7) }
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns the first half of the players, rounded downwards" do
        bracket.s1_numbers.should == [1, 2, 3]
      end
    end
  end

  describe "#s2" do
    context "even number of players" do
      let(:players) { create_players(1..6) }
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns the second half of the players" do
        bracket.s2_numbers.should == [4, 5, 6]
      end
    end

    context "odd number of players" do
      let(:players) { create_players(1..7) }
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns the second half of the players, rounded upwards" do
        bracket.s2_numbers.should == [4, 5, 6, 7]
      end
    end
  end

  describe "#transpose" do
    let(:s1_players) { create_players(1..5) }
    let(:s2_players) { create_players(6..11) }
    let(:bracket) { Swissfork::Bracket.new(s1_players + s2_players) }

    context "first transposition" do
      it "transposes the lowest player" do
        bracket.transpose
        bracket.s2_numbers.should == [6, 7, 8, 9, 11, 10]
      end
    end

    context "second transposition" do
      before(:each) { bracket.send(:"s2_numbers=", [6, 7, 8, 9, 11, 10]) }

      it "transposes the next lowest player" do
        bracket.transpose
        bracket.s2_numbers.should == [6, 7, 8, 10, 9, 11]
      end
    end

    context "third transposition" do
      before(:each) { bracket.send(:"s2_numbers=", [6, 7, 8, 10, 9, 11]) }

      it "transposes the next lowest player" do
        bracket.transpose
        bracket.s2_numbers.should == [6, 7, 8, 10, 11, 9]
      end
    end

    context "last transposition" do
      before(:each) { bracket.send(:"s2_numbers=", [11, 10, 9, 8, 6, 7]) }

      it "transposes every player" do
        bracket.transpose
        bracket.s2_numbers.should == [11, 10, 9, 8, 7, 6]
      end
    end

    context "transposition limit reached" do
      before(:each) { bracket.send(:"s2_numbers=", [11, 10, 9, 8, 7, 6]) }

      it "exchanges players" do
        bracket.transpose
        bracket.s1_numbers.should == [1, 2, 3, 4, 6]
        bracket.s2_numbers.should == [5, 7, 8, 9, 10, 11]
      end
    end

    context "an exchange has already taken place" do
      before(:each) do
        bracket.send(:"s1_numbers=", [1, 2, 3, 4, 6])
        bracket.send(:"s2_numbers=", [5, 7, 8, 9, 10, 11])
      end

      it "transposes the lowest players in s2" do
        bracket.transpose
        bracket.s2_numbers.should == [5, 7, 8, 9, 11, 10]
      end
    end
  end

  describe "#exchange" do
    let(:s1_players) { create_players(1..5) }
    let(:s2_players) { create_players(6..11) }
    let(:bracket) { Swissfork::Bracket.new(s1_players + s2_players) }

    context "first exchange" do
      it "exchanges the closest players" do
        bracket.exchange
        bracket.s1_numbers.should == [1, 2, 3, 4, 6]
        bracket.s2_numbers.should == [5, 7, 8, 9, 10, 11]
      end
    end

    context "second exchange" do
      before(:each) do
        bracket.send(:"s1_numbers=", [1, 2, 3, 4, 6])
        bracket.send(:"s2_numbers=", [5, 7, 8, 9, 10, 11])
      end

      it "exchanges the next closest players, choosing the bottom player from S1" do
        bracket.exchange
        bracket.s1_numbers.should == [1, 2, 3, 4, 7]
        bracket.s2_numbers.should == [5, 6, 8, 9, 10, 11]
      end
    end

    context "third exchange" do
      before(:each) do
        bracket.send(:"s1_numbers=", [1, 2, 3, 4, 7])
        bracket.send(:"s2_numbers=", [5, 6, 8, 9, 10, 11])
      end

      it "exchanges the next closest players" do
        bracket.exchange
        bracket.s1_numbers.should == [1, 2, 3, 5, 6]
        bracket.s2_numbers.should == [4, 7, 8, 9, 10, 11]
      end
    end

    context "exchanges limit reached" do
      before(:each) do
        bracket.send(:"s1_numbers=", [2, 3, 4, 5, 11])
        bracket.send(:"s2_numbers=", [1, 6, 7, 8, 9, 10])
      end

      pending "it aborts the pairing" do
        bracket.exchange
        # TODO: raise exception? Return false?
      end
    end
  end

  describe "#pair_numbers" do
    context "even number of players" do
      let(:players) { create_players(1..10) }
      let(:bracket) { Swissfork::Bracket.new(players) }
      before(:each) do
        players.each { |player| player.stub(:opponents).and_return([]) }
      end

      context "no previous opponents" do
        it "pairs the players from s1 with the players from s2" do
          bracket.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
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
      let(:bracket) { Swissfork::Bracket.new(players) }
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
  end
end
