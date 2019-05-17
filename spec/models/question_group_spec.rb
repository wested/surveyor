# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuestionGroup do
  let(:question_group){ create(:question_group) }
  let(:dependency){ create(:dependency) }
  let(:response_set){ create(:response_set) }

  context "when creating" do
    it { expect(question_group).to be_valid }
    it "#display_type = inline by default" do
      question_group.display_type = "inline"
      expect(question_group.renderer).to eq(:inline)
    end
    it "#renderer == 'default' when #display_type = nil" do
      question_group.display_type = nil
      expect(question_group.renderer).to eq(:default)
    end
    it "interprets symbolizes #display_type to #renderer" do
      question_group.display_type = "foo"
      expect(question_group.renderer).to eq(:foo)
    end
    it "reports DOM ready #css_class based on dependencies" do
      question_group.dependency = dependency
      expect(dependency).to receive(:is_met?).and_return(true)
      expect(question_group.css_class(response_set)).to eq("g_dependent")

      expect(dependency).to receive(:is_met?).and_return(false)
      expect(question_group.css_class(response_set)).to eq("g_dependent g_hidden")

      question_group.custom_class = "foo bar"
      expect(dependency).to receive(:is_met?).and_return(false)
      expect(question_group.css_class(response_set)).to eq("g_dependent g_hidden foo bar")
    end
  end

  context "with translations" do
    require 'yaml'
    let(:survey){ create(:survey) }
    let(:survey_section){ create(:survey_section) }
    let(:survey_translation){
      create(:survey_translation, :locale => :es, :translation => {
        :question_groups => {
          :goodbye => {
            :text => "¡Adios!"
          }
        }
      }.to_yaml)
    }
    let(:question){ create(:question) }
    before do
      question_group.text = "Goodbye"
      question_group.reference_identifier = "goodbye"
      question_group.questions = [question]
      question.survey_section = survey_section
      survey_section.survey = survey
      survey.translations << survey_translation
    end
    it "returns its own translation" do
      expect(question_group.translation(:es)[:text]).to eq("¡Adios!")
    end
    it "returns its own default values" do
      expect(question_group.translation(:de)).to eq({"text" => "Goodbye", "help_text" => nil})
    end
  end
end
