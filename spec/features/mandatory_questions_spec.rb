require 'spec_helper'

describe "saving with ajax", js: true do
  include_context "numbers_mandatory"

  it "receive error if all questions not answered" do
    start_survey('Numbers Mandatory')
    expect(page).to have_content("What is one plus one?")

    click_button "Next section"
    wait_for_ajax

    click_button "Click here to finish"

    # page.save_screenshot(File.join(Rails.root, "tmp", "surveyor.png"), :full => true)
    within ".surveyor_flash" do
      expect(page).to have_content "You must complete all required fields before submitting the survey."
      expect(page).to have_content "Addition"
      expect(page).to have_content "What is one plus one?"
      expect(page).to have_content "What is five plus one?"
      expect(page).to have_content "Literature"
      expect(page).to have_content "What is the 'Answer to the Ultimate Question of Life, The Universe, and Everything'"
    end
  end
end