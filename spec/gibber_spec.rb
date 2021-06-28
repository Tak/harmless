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

  context "response heuristics" do
    it "doesn't respond when periodicity is disabled" do
      gibber = Harmless::Gibber.new(nil, nil, 0)
      100.times do |i|
        expect(gibber.should_respond("", 0, i)).to eq(false)
      end
    end

    it "doesn't respond to every message" do
      gibber = Harmless::Gibber.new(nil, nil)
      responses = 100.times.select{ gibber.should_respond("", 100, 1) }
      expect(responses.size).to be < 10
    end

    it "responds within periodicity" do
      gibber = Harmless::Gibber.new(nil, nil)
      [10, 100, 1000].each do |period|
        expect((period * 2).times.detect { |i| gibber.should_respond("", period, i) }).not_to be_nil
      end
    end
  end

  context "message preprocessing" do
    it "filters whole-message emote formatting" do
      gibber = Harmless::Gibber.new(nil, nil)
      {
        "_foo_" => "foo",
        "_foo bar baz_" => "foo bar baz",
        "_foo_bar_baz_" => "foo_bar_baz"
      }.each do |input, output|
        expect(gibber.preprocess_text(input)).to eq(output)
      end
    end

    it "filters spoiler formatting" do
      gibber = Harmless::Gibber.new(nil, nil)
      {
        "||snape marries dumbledore!!!||" => "snape marries dumbledore!!!",
        "||https://nsfw.url|| << don't visit that nsfw url!" => "https://nsfw.url << don't visit that nsfw url!",
        "||Jenny||'s phone number is ||867 5309||" => "Jenny's phone number is 867 5309",
        "return foo || bar;" => "return foo || bar;"
      }.each do |input, output|
        expect(gibber.preprocess_text(input)).to eq(output)
      end
    end

    it "applies phrase formatting per-token" do
      gibber = Harmless::Gibber.new(nil, nil)
      {
        "I *don't want* to" => "I *don't* *want* to",
        "I **don't want** to" => "I **don't** **want** to",
        "I ***don't want*** to" => "I ***don't*** ***want*** to",
        "I ~~don't want~~ to" => "I ~~don't~~ ~~want~~ to",
        "I _am really *very* upset_" => "I _am_ _really_ _*very*_ _upset_",
        "*do want to" => "*do want to",
        ">  but what do *you mean*" => "but what do *you* *mean*"
      }.each do |input, output|
        expect(gibber.preprocess_text(input)).to eq(output)
      end
    end
  end
end
