require "harmless/reeval"

RSpec.describe Harmless::REEval do
  context "message preprocessing" do
    it "doesn't mangle 'normal' messages" do
      reeval = Harmless::REEval.new(nil, nil)
      [
        "foo bar baz",
        "_foo_ bar baz",
        "foo bar _baz_",
        "_foo_ bar _baz_",
        "foo <bar> baz",
        "foo <@bar> baz",
        "foo <@!bar> baz",
        "foo <#bar> baz",
        "__",
      ].each do |input|
        expect(reeval.preprocess_message(input, nil)).to eq(input)
      end
    end

    it "trims leading/trailing whitespace" do
      reeval = Harmless::REEval.new(nil, nil)
      {
        "   " => "",
        " foo bar baz" => "foo bar baz",
        "foo bar baz  " => "foo bar baz",
        " foo bar baz " => "foo bar baz",
      }.each do |input, output|
        expect(reeval.preprocess_message(input, nil)).to eq(output)
      end
    end

    it "attempts to replace embedded ids" do
      reeval = Harmless::REEval.new(nil, nil)
      [
        "<@123456> <bar> baz",
        "foo <@123456> baz",
        "foo <@!bar> <@!123456>",
        "<#123456> <bar> baz",
        "foo <#123456> baz",
        "foo <#bar> <#123456>",
        "<@123456>",
        "<@!123456>",
        "<#123456>",
      ].each do |input|
        # Raising error here because we don't actually have a server connection and I'm too lazy to mock it,
        # but the error implies that the lookup codepath was taken
        expect { reeval.preprocess_message(input, nil) }.to raise_error(NoMethodError)
      end
    end

    it "fixes up 'emote' markup" do
      reeval = Harmless::REEval.new(nil, nil)
      {
        "_foo bar baz_" => "\001ACTIONfoo bar baz\001",
        "_ _" => "\001ACTION \001",
      }.each do |input, output|
        expect(reeval.preprocess_message(input, nil)).to eq(output)
      end
    end
    # message preprocessing
  end

  context "replacement" do
    it "performs replacement in 'normal' messages" do
      reeval = Harmless::REEval.new(nil, nil)
      # Prime message store
      [
        "¡Yo me gusta los plátanos!",
        "#helping"
      ].each { |message| reeval.do_process_message("PlátanoHombre", "banana", 0, reeval.preprocess_message(message, nil)) }

      {
        "1s,Y,N" => "¡No me gusta los plátanos!",
        "1s,h,y" => "#yelping",
      }.each do |input, output|
        reeval.do_process_message("PlátanoHombre", "banana", 0, reeval.preprocess_message(input, nil)) do |_, _, _, text|
          expect(text).to eq(output)
        end
      end
    end

    it "performs replacement in 'emotes'" do
      reeval = Harmless::REEval.new(nil, nil)
      # Prime message store
      [
        "_se gusta los plátanos_",
      ].each do |message|
        reeval.do_process_message("PlátanoHombre", "banana", 0,
          reeval.preprocess_message(message, nil))
      end
      {
        "s,^,no ," => "\001ACTIONno se gusta los plátanos\001",
        "s,.*,¿\\&?," => "\001ACTION¿no se gusta los plátanos?\001",
        "s,plátan,tac," => "\001ACTION¿no se gusta los tacos?\001",
      }.each do |input, output|
        reeval.do_process_message("PlátanoHombre", "banana", 0,
          reeval.preprocess_message(input, nil)) do |_, _, _, text|
          expect(text).to eq(output)
        end
      end
    end

    it "performs replacement in 'quotes'" do
      reeval = Harmless::REEval.new(nil, nil)
      # Prime message store
      [
        "> Yo me gusta los plátanos",
      ].each do |message|
        reeval.do_process_message("PlátanoHombre", "banana", 0,
          reeval.preprocess_message(message, nil))
      end
      {
        # "s,.,N," => "> No me gusta los plátanos", #FIXME
        "s,Y,N," => "> No me gusta los plátanos",
      }.each do |input, output|
        reeval.do_process_message("PlátanoHombre", "banana", 0,
          reeval.preprocess_message(input, nil)) do |_, _, _, text|
          expect(text).to eq(output)
        end
      end
    end
  end
end
