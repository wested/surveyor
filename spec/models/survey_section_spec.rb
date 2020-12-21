# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SurveySection do
    let(:survey_section){ create(:survey_section) }

  context "when creating" do
    it "is invalid without #title" do
      survey_section.title = nil
      survey_section.valid?
      expect(survey_section.errors[:title].size).to eq(1)
    end
  end

  context "with questions" do
    let!(:question_2){ create(:question, :survey_section => survey_section, :text => "Little")}
    let!(:question_1){ create(:question, :survey_section => survey_section, :text => "Peep")}
    let!(:question_3){ create(:question, :survey_section => survey_section, display_order: 2, :text => "Bo")}
    # before do
    #   [question_1, question_2, question_3].each{|q| survey_section.questions << q }
    # end
    it{ expect(survey_section.questions.size).to eq(3)}
    it "gets questions in order" do
      expect(survey_section.questions.order("display_order asc").to_a).to eq([question_2, question_3, question_1])
      expect(survey_section.questions.order("display_order asc").map(&:display_order)).to eq([1,2,3])
    end
    it "deletes child questions when deleted" do
      question_ids = survey_section.questions.map(&:id)
      survey_section.destroy
      question_ids.each{|id| expect(Question.find_by_id(id)).to be_nil}
    end
  end

  context "with translations" do
    require 'yaml'
    let(:survey){ create(:survey) }
    let(:survey_translation){
      create(:survey_translation, :locale => :es, :translation => {
        :survey_sections => {
          :one => {
            :title => "Uno"
          }
        }
      }.to_yaml)
    }
    before do
      survey_section.reference_identifier = "one"
      survey_section.survey = survey
      survey.translations << survey_translation
    end
    it "returns its own translation" do
      expect(YAML.load(survey_translation.translation)).not_to be_nil
      expect(survey_section.translation(:es)[:title]).to eq("Uno")
    end
    it "returns its own default values" do
      expect(survey_section.translation(:de)).to eq({"title" => survey_section.title, "description" => survey_section.description})
    end
  end
end
