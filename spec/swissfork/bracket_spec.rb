require "swissfork/bracket"

describe Swissfork::Bracket do
  def create_players(numbers)
    numbers.map { |number| double(:number => number) }
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
end
