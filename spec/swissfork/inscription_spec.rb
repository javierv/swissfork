require "spec_helper"
require "swissfork/inscription"

module Swissfork
  describe Inscription do
    let(:inscription) { Inscription.new(2150, "Bertrand Russell") }

    describe "#<=>" do
      context "the other person has more rating" do
        let(:arrival) { Inscription.new(2235, "Arthur Conan Doyle") }

        it "is bigger" do
          inscription.should be > arrival
        end
      end

      context "the other person has less rating" do
        let(:arrival) { Inscription.new(2005, "Edgar Allan Poe") }

        it "is smaller" do
          inscription.should be < arrival
        end
      end

      context "the other person has the same rating" do
        let(:arrival) { Inscription.new(2150, "Agatha Christie") }

        it "orders them based on their names" do
          inscription.should be > arrival
        end
      end
    end
  end
end
