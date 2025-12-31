require_relative '../app/Timesheets'

RSpec.describe "Timesheets Logic" do
  describe "#minutes_from_note" do
    it "correctly parses 'add 1d 2h 30m of time spent'" do
      expect(minutes_from_note("add 1d 2h 30m of time spent")).to eq(1590)
    end

    it "correctly parses 'sub 1h of time spent'" do
      expect(minutes_from_note("sub 1h of time spent")).to eq(-60)
    end

    it "correctly parses 'add 45m of time spent'" do
      expect(minutes_from_note("add 45m of time spent")).to eq(45)
    end

    it "correctly parses 'sub 1d of time spent'" do
      expect(minutes_from_note("sub 1d of time spent")).to eq(-1440)
    end

    it "returns 0 for an empty string" do
      expect(minutes_from_note("")).to eq(0)
    end

    it "returns 0 for non-matching notes" do
      expect(minutes_from_note("just a random comment")).to eq(0)
    end
  end
end
