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
      ].each { |message| reeval.do_process_message("PlátanoHombre", "banana", 0, reeval.preprocess_message(message, nil), nil, nil) }

      {
        "1s,Y,N" => "¡No me gusta los plátanos!",
        "1s,h,y" => "#yelping",
      }.each do |input, output|
        reeval.do_process_message("PlátanoHombre", "banana", 0, reeval.preprocess_message(input, nil), nil, nil) do |_, _, _, text|
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
          reeval.preprocess_message(message, nil), nil, nil)
      end
      {
        "s,^,no ," => "\001ACTIONno se gusta los plátanos\001",
        "s,.*,¿\\&?," => "\001ACTION¿no se gusta los plátanos?\001",
        "s,plátan,tac," => "\001ACTION¿no se gusta los tacos?\001",
      }.each do |input, output|
        reeval.do_process_message("PlátanoHombre", "banana", 0,
          reeval.preprocess_message(input, nil), nil, nil) do |_, _, _, text|
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
          reeval.preprocess_message(message, nil), nil, nil)
      end
      {
        # "s,.,N," => "> No me gusta los plátanos", #FIXME
        "s,Y,N," => "> No me gusta los plátanos",
      }.each do |input, output|
        reeval.do_process_message("PlátanoHombre", "banana", 0,
          reeval.preprocess_message(input, nil), nil, nil) do |_, _, _, text|
          expect(text).to eq(output)
        end
      end
    end

    it "doesn't output replacements that result in empty emotes" do
      reeval = Harmless::REEval.new(nil, nil)
      # Prime message store
      [
        "_gusta los plátanos_",
      ].each do |message|
        reeval.do_process_message("PlátanoHombre", "banana", 0,
                                  reeval.preprocess_message(message, nil), nil, nil)
      end
      [
        "s,Y,N",
      ].each do |input|
        reeval.do_process_message("PlátanoHombre", "banana", 0, reeval.preprocess_message(input, nil), nil, nil) do |_, _, _, text|
          raise "Got unexpected replacement #{text}"
        end
      end
    end

    context "when replying directly" do
      it "performs replacement in replies to self" do
        reeval = Harmless::REEval.new(nil, nil)
        [
          ["s,Y,N", "¡No me gusta los plátanos!", "¡Yo me gusta los plátanos!"],
          ["s,h,y", "#yelping", "#helping"],
        ].each do |input, output, referenced|
          reeval.do_process_message("PlátanoHombre", "banana", 0, reeval.preprocess_message(input, nil), nil, referenced) do |_, _, _, text|
            expect(text).to eq(output)
          end
        end
      end

      it "performs replacement in replies to others" do
        reeval = Harmless::REEval.new(nil, nil)
        msg_to = "BananManden"
        [
          ["s,Y,N", "¡No me gusta los plátanos!", "¡Yo me gusta los plátanos!"],
          ["s,h,y", "#yelping", "#helping"],
        ].each do |input, output, referenced|
          reeval.do_process_message("PlátanoHombre", "banana", 0, reeval.preprocess_message(input, nil), msg_to, referenced) do |_, to, _, text|
            expect(text).to eq(output)
            expect(to).to eq(msg_to)
          end
        end
      end

      it "doesn't include replacement display header in chained replacements" do
        reeval = Harmless::REEval.new(nil, nil)
        chained_reply_author = "wat"
        previous_reply_author = "BananManden"
        [
          ["PlátanoHombre", "¡Yo me gusta los plátanos!"],
        ].each do |content_author, base_content|
          reply_author, reply_content = reeval.update_author_content_from_chained_replacement_header(chained_reply_author, "#{content_author} meant: #{base_content}")
          expect(reply_author).to eq(content_author)
          expect(reply_content).to eq(base_content)

          reply_author, reply_content = reeval.update_author_content_from_chained_replacement_header(chained_reply_author, "#{content_author} thinks #{previous_reply_author} meant: #{base_content}")
          expect(reply_author).to eq(content_author)
          expect(reply_content).to eq(base_content)
        end
      end

      it "doesn't output replacements that result in empty emotes" do
        reeval = Harmless::REEval.new(nil, nil)
        msg_to = "BananManden"
        [
          ["s,Y,N", "_gusta los plátanos_"],
        ].each do |input, referenced|
          reeval.do_process_message("PlátanoHombre", "banana", 0, reeval.preprocess_message(input, nil), msg_to, reeval.preprocess_message(referenced, nil)) do |_, _, _, text|
            raise "Got unexpected replacement #{text}"
          end
        end
      end
    end
  end
end
