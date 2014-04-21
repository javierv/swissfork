require "swissfork/bracket"

describe Swissfork::Bracket do
  describe "#maximum_number_of_pairs" do
    context "even number of players" do
      let(:players) { (1..6).map { double }}
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns half of the number of players" do
        bracket.maximum_number_of_pairs.should == 3
      end
    end

    context "odd number of players" do
      let(:players) { (1..7).map { double }}
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns half of the number of players rounded downwards" do
        bracket.maximum_number_of_pairs.should == 3
      end
    end
  end

  describe "#s1" do
    context "even number of players" do
      let(:players) { (1..6).map { |n| double(:number => n) }}
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns the first half of the players" do
        bracket.s1.map(&:number).should == [1, 2, 3]
      end
    end

    context "odd number of players" do
      let(:players) { (1..7).map { |n| double(:number => n) }}
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns the first half of the players, rounded downwards" do
        bracket.s1.map(&:number).should == [1, 2, 3]
      end
    end
  end

  describe "#s2" do
    context "even number of players" do
      let(:players) { (1..6).map { |n| double(:number => n) }}
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns the second half of the players" do
        bracket.s2.map(&:number).should == [4, 5, 6]
      end
    end

    context "odd number of players" do
      let(:players) { (1..7).map { |n| double(:number => n) }}
      let(:bracket) { Swissfork::Bracket.new(players) }

      it "returns the second half of the players, rounded upwards" do
        bracket.s2.map(&:number).should == [4, 5, 6, 7]
      end
    end
  end
end
