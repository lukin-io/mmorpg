# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicFightLogsHelper, type: :helper do
  let(:bandit) { instance_double(ArenaParticipation, participant_name: "Bandit") }
  let(:player) { instance_double(ArenaParticipation, participant_name: "Hero") }

  def formatted(message, type: "damage", team_a: [bandit], team_b: [player])
    Nokogiri::HTML.fragment(helper.combat_log_message(message, type:, team_a:, team_b:))
  end

  it "emphasizes historical names, critical damage and body parts without bolding the whole sentence" do
    message = "Hero critical hit (head) Bandit for -686 [0/605]"
    html = formatted(message, type: "critical")

    expect(html.text).to eq(message)
    expect(html.at_css("strong.nl-log-name--alpha").text).to eq("Bandit")
    expect(html.at_css("strong.nl-log-name--beta").text).to eq("Hero")
    expect(html.at_css("strong.nl-log-damage--critical").text).to eq("-686")
    expect(html.at_css(".nl-log-body-part").text).to eq("(head)")
    expect(html.css("strong").map(&:text)).not_to include("critical hit")
  end

  it "preserves zero damage, shield wording, defeat, empty search and the named injury" do
    expect(formatted("Bandit pierced Hero's shield (torso) for -0 [0/1375]").at_css("strong.nl-log-damage").text).to eq("-0")
    expect(formatted("Bandit has been defeated!").css("strong").map(&:text)).to include("has been defeated!")
    expect(formatted("Hero searched Bandit. Result: nothing found.").css("strong").map(&:text)).to include("nothing found.")
    injury = formatted("Hero suffered a light injury «Pectoral muscle hematoma».", type: "injury")
    expect(injury.at_css("strong.nl-log-injury").text).to eq("«Pectoral muscle hematoma»")
  end

  it "escapes malicious names and message fragments, including quoted injury names" do
    malicious = instance_double(ArenaParticipation, participant_name: "<img src=x onerror=alert(1)>")
    message = "#{malicious.participant_name} hit Hero for -4. «<script>alert(2)</script>»"
    html = formatted(message, type: "injury", team_a: [malicious])
    expect(html.text).to eq(message)
    expect(html.css("img, script, [onerror]")).to be_empty
    expect(html.css("strong.nl-log-name--alpha").size).to eq(1)
  end

  it "formats a log with no participants and prefers a complete longer name" do
    expect(formatted("Victory: nobody.", team_a: [], team_b: []).text).to eq("Victory: nobody.")
    longer = instance_double(ArenaParticipation, participant_name: "Bandit Captain")
    html = formatted("Bandit Captain missed Bandit (torso)", team_b: [longer])
    expect(html.at_css(".nl-log-name--beta").text).to eq("Bandit Captain")
    expect(html.at_css(".nl-log-name--alpha").text).to eq("Bandit")
  end
end
