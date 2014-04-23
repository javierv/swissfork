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
  end
end
