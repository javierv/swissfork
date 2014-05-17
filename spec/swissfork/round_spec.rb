require "swissfork/round"

describe Swissfork::Round do
  def create_players(numbers)
    numbers.map { |number| double(number: number, points: 0) }
  end

  describe "#brackets" do
    context "players with the same points" do
      let(:players) { create_players(1..6) }

      it "returns only one bracket" do
        Swissfork::Round.new(players).brackets.should have(1).element
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

      let(:brackets) { Swissfork::Round.new(players).brackets }

      it "returns as many brackets as different points" do
        brackets.should have(4).elements
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
end
