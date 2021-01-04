require 'spec_helper'

describe "preventing duplicates", js: true do
  include_context "everything"
  it "saves a simple radio button response" do
    response_set = start_survey('Everything')
    expect(page).to have_content("What is your favorite color?")
    blue = Answer.find_by text: "blue"
    red = Answer.find_by text: "red"
    within question("1") do
      find("input[value='#{blue.id}']").trigger('click')
      find("input[value='#{red.id}']").trigger('click')
    end
    wait_for_ajax
    expect(response_set.count).to eq(1)
    expect(response_set.for("1", "r").count).to eq(1)
  end
  it "saves a simple checkbox response" do
    response_set = start_survey('Everything')
    expect(page).to have_content("Choose the colors you don't like")
    purple = Answer.find_by text: "purple"
    orange = Answer.find_by text: "orange"
    brown = Answer.find_by text: "brown"

    within question("2b") do
      find("input[value='#{purple.id}']").trigger('click')
      find("input[value='#{orange.id}']").trigger('click')
      find("input[value='#{orange.id}']").trigger('click')
      find("input[value='#{brown.id}']").trigger('click')
    end
    wait_for_ajax
    expect(response_set.count).to eq(2)
    expect(response_set.for("2b", "1").count).to eq(0)
    expect(response_set.for("2b", "2").count).to eq(1)
    expect(response_set.for("2b", "3").count).to eq(1)
  end
  it "saves a string response" do
    response_set = start_survey('Everything')
    expect(page).to have_content("What is the best color for a fire engine?")
    within question("fire_engine") do
      fill_in "Color", with: "yellow"
    end

    purple = Answer.find_by text: "purple"
    within question("2b") do
      find("input[value='#{purple.id}']").trigger('click')
    end

    within question("fire_engine") do
      fill_in "Color", with: "red"
    end
    within question("2b") do
      find("input[value='#{purple.id}']").trigger('click')
    end
    wait_for_ajax
    expect(response_set.count).to eq(1)
    expect(response_set.for("fire_engine", "color").first.string_value).to eq("red")
  end
end