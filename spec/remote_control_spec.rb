# frozen_string_literal: true

require "harmless/remote_control"

RSpec.describe Harmless::RemoteControl do
  it "parses GRUEDUMP" do
    expect(Harmless::RemoteControl.parse_command("GRUEDUMP")).to eq([:gruedump, []])
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

  it "rejects unknown commands" do
    %w[GREUDUMP BANANA NO_U WAT].each do |command|
      expect(Harmless::RemoteControl.parse_command(command)).to eq(nil)
    end
  end

  it "rejects commands with wrong number of arguments" do
    [
      "GRUEDUMP #banana blahblahblah",
      "DELETE 1",
      "MSG #banana",
      "REACT #banana :wat:",
      "REACT #banana PlátanoHombre 1 :wat: :no_u:"
    ].each do |command|
      expect(Harmless::RemoteControl.parse_command(command)).to eq(nil)
    end
  end

  it "rejects commands with wrong argument types" do
    [
      "DELETE banana 1",
      "DELETE #banana NO_U",
      "MSG banana banana",
      "REACT #banana PlátanoHombre :wat: :no_u:"
    ].each do |command|
      expect(Harmless::RemoteControl.parse_command(command)).to eq(nil)
    end
  end
end
