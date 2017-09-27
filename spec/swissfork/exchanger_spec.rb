require "swissfork/exchanger"
require "swissfork/player"

module Swissfork
  describe Exchanger do
    def create_players(numbers)
      numbers.map { |number| double(number: number, inspect: number) }
    end

    describe "#next" do
      let(:s1_players) { create_players(1..5) }
      let(:s2_players) { create_players(6..11) }
      let(:exchanger) { Exchanger.new(s1_players, s2_players) }

      context "first exchange" do
        before(:each) { exchanger.next }

        it "exchanges the closest players" do
          exchanger.numbers.should == [1, 2, 3, 4, 6, 5, 7, 8, 9, 10, 11]
        end
      end

      context "second exchange" do
        before(:each) { 2.times { exchanger.next }}

        it "exchanges the next closest players, choosing the bottom player from S1" do
          exchanger.numbers.should == [1, 2, 3, 4, 7, 6, 5, 8, 9, 10, 11]
        end
      end

      context "third exchange" do
        before(:each) { 3.times { exchanger.next }}

        it "exchanges the next closest players" do
          exchanger.numbers.should == [1, 2, 3, 6, 5, 4, 7, 8, 9, 10, 11]
        end
      end
    end
  end
end
