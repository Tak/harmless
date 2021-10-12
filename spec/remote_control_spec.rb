# frozen_string_literal: true

require "harmless/remote_control"

RSpec.describe Harmless::RemoteControl do
  it "parses GRUEDUMP" do
    expect(Harmless::RemoteControl.parse_command("GRUEDUMP")).to eq([:gruedump, []])
  end

  it "parses GIBBERDUMP" do
    expect(Harmless::RemoteControl.parse_command("GIBBERDUMP")).to eq([:gibberdump, []])
  end

  it "parses MSG" do
    expect(Harmless::RemoteControl.parse_command("MSG #banana banana!!!")).to eq([:msg, %w[banana banana!!!]])
  end

  it "parses DELETE" do
    expect(Harmless::RemoteControl.parse_command("DELETE #banana 1")).to eq([:delete, ["banana", 1]])
  end

  it "parses REACT" do
    expect(Harmless::RemoteControl.parse_command("REACT #banana PlátanoHombre 3 :banana:"))
      .to eq([:react, ["banana", "PlátanoHombre", 3, ":banana:"]])
  end

  it "parses GIBBER_PERIOD" do
    expect(Harmless::RemoteControl.parse_command("GIBBER_PERIOD 20")).to eq([:gibber_period, [20]])
  end

  it "parses GIBBER_METHOD" do
    expect(Harmless::RemoteControl.parse_command("GIBBER_METHOD nlp")).to eq([:gibber_method, ["nlp"]])
  end

  it "rejects unknown commands" do
    %w[GREUDUMP BANANA NO_U WAT].each do |command|
      expect(Harmless::RemoteControl.parse_command(command)).to eq(nil)
    end
  end

  it "rejects commands with wrong number of arguments" do
    [
      "GRUEDUMP #banana blahblahblah",
      "GIBBERDUMP 1",
      "DELETE 1",
      "MSG #banana",
      "REACT #banana :wat:",
      "REACT #banana PlátanoHombre 1 :wat: :no_u:",
      "GIBBER_PERIOD",
      "GIBBER_PERIOD #sslug 20",
      "GIBBER_METHOD",
      "GIBBER_METHOD #sslug 20",
    ].each do |command|
      expect(Harmless::RemoteControl.parse_command(command)).to eq(nil)
    end
  end

  it "rejects commands with wrong argument types" do
    [
      "DELETE banana 1",
      "DELETE #banana NO_U",
      "MSG banana banana",
      "REACT #banana PlátanoHombre :wat: :no_u:",
      "GIBBER_PERIOD banana"
    ].each do |command|
      expect(Harmless::RemoteControl.parse_command(command)).to eq(nil)
    end
  end
end
