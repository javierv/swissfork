require "create_players_helper"
require "swissfork/limbo_exchanger"

module Swissfork
  describe LimboExchanger do
    describe "#limit_reached?" do
      let(:exchanger) { LimboExchanger.new(s1_players, s2_players) }

      context "two players in s1 and two players in s2" do
        let(:s1_players) { create_players(1..2) }
        let(:s2_players) { create_players(3..4) }

        context "all individual exchanges done" do
          before(:each) { 4.times { exchanger.next_exchange }}

          it "returns false" do
            exchanger.limit_reached?.should be false
          end
        end

        context "exchanges of two players also done" do
          before(:each) { 5.times { exchanger.next_exchange }}

          it "returns false" do
            exchanger.limit_reached?.should be true
          end
        end
      end
    end
  end
end
