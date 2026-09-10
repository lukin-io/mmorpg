require "rails_helper"

RSpec.describe "shared/_building_entrance", type: :view do
  it "renders original decorative artwork with the shared aspect and resize owner" do
    render partial: "shared/building_entrance", locals: {asset: "shop/interior.png"}

    document = Nokogiri::HTML.fragment(rendered)
    entrance = document.at_css(".nl-building-entrance[data-controller='nl-building-entrance']")
    image = entrance.at_css("img.nl-building-entrance__image")

    expect(entrance["aria-hidden"]).to eq("true")
    expect(image["src"]).to include("shop/interior")
    expect(image.attributes.slice("alt", "width", "height").transform_values(&:value))
      .to eq("alt" => "", "width" => "1250", "height" => "600")
    expect(entrance.css("a, button, input")).to be_empty
  end
end
