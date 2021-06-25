RSpec.describe Harmless::Gibber do
  context "ingestion filtering" do
    it "ingests normal text" do
      gibber = Harmless::Gibber.new(nil, nil)
      [
        "different playstyles",
        "the client laptop I got for work has an SSL interceptor installed directly on it",
        "all ssl certs are blocked and replaced with the built-in one, which is presumably sending everything back to IT",
        "mom???",
        "the clowns are so much better on discord",
        "make sure to use it for all of your banking!",
        "ok!",
        "I'm only going to use it for working on this client's stuff",
        "and porn",
        "those mitm approaches are increasingly common",
        "and still fucking horrible",
        "Mr Rogers repeatedly putting on that clown mask will haunt my dreams for a week.",
        "it's a b "
      ].each do |input|
        expect(gibber.should_ingest(input)).to eq(true)
      end
    end

    it "doesn't ingest dice rolls" do
      gibber = Harmless::Gibber.new(nil, nil)
      [
        "PlátanoHombre Roll: [10] Result: 10",
        "Tak! Roll: [10] Result: 10",
        "PlátanoHombre  Roll: [50, 49, 49, 47, 46, 45, 43, 42, 33, 32, 32, 26, 26, 25, 23, 22, 17, 13, 12, 8, 7, 5, 4, 3, 2] Result: 661",
        "PlátanoHombre Roll: [4, 3, 2, 2] Result: 11 Reason: subpar rollerbot",
        "PlátanoHombre Roll: `[10]` Result: 10",
        "Tak! Roll: `[10]` Result: 10",
        "PlátanoHombre  Roll: `[50, 49, 49, 47, 46, 45, 43, 42, 33, 32, 32, 26, 26, 25, 23, 22, 17, 13, 12, 8, 7, 5, 4, 3, 2]` Result: 661",
        "PlátanoHombre Roll: `[4, 3, 2, 2]` Result: 11 Reason: `subpar rollerbot`"
      ].each do |input|
        expect(gibber.should_ingest(input)).to eq(false)
      end
    end

    it "doesn't ingest regexes" do
      gibber = Harmless::Gibber.new(nil, nil)
      [
        "s,Y,N",
        "s,Y ,N,",
        "s,Y,N,gi",
        "s,Y,N,30%",
        "tr,Y,N",
        "tr,Y,N,",
        "tr,Y,N,gi",
        "tr,Y,N,30%",
      ].each do |input|
        expect(gibber.should_ingest(input)).to eq(false)
      end
    end
  end
end
