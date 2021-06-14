require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SurveyorController, type: :request do

  let!(:survey)           { create(:survey, :title => "Alphabet", :access_code => "alpha", :survey_version => 0)}
  let!(:survey_beta)      { create(:survey, :title => "Alphabet", :access_code => "alpha", :survey_version => 1)}
  let!(:response_set)      { create(:response_set, :survey => survey, :access_code => "pdq")}
  let!(:response_set_beta) { create(:response_set, :survey => survey_beta, :access_code => "rst")}
  before { allow(ResponseSet).to receive(:create).and_return(response_set) }

  # match '/', :to                                     => 'surveyor#index', :as    => 'available_surveys', :via => :get
  # match '/:survey_code', :to                         => 'surveyor#create', :as => 'take_survey', :via       => :post
  # match '/:survey_code', :to                         => 'surveyor#export', :as => 'export_survey', :via     => :get
  # match '/:survey_code/:response_set_code', :to      => 'surveyor#show', :as   => 'view_my_survey', :via    => :get
  # match '/:survey_code/:response_set_code/take', :to => 'surveyor#edit', :as   => 'edit_my_survey', :via    => :get
  # match '/:survey_code/:response_set_code', :to      => 'surveyor#update', :as => 'update_my_survey', :via  => :put

  context "#index" do
    def do_get
      get surveyor.available_surveys_path
    end
    it "renders index" do
      do_get
      expect(response).to be_successful
      expect(response).to render_template('index')
    end
    it "assigns surveys_by_access_code" do
      do_get
      expect(assigns(:surveys_by_access_code)).to eq({"alpha" => [survey_beta,survey]})
    end
  end

  context "#create" do
    def do_post(params = {})
      post surveyor.take_survey_path({:survey_code => "alpha"}.merge(params))
    end
    it "finds latest version" do
      do_post
      expect(assigns(:survey)).to eq(survey_beta)
    end
    it "finds specified survey_version" do
      do_post :survey_version => 0
      expect(assigns(:survey)).to eq(survey)
    end
    it "creates a new response_set" do
      expect(ResponseSet).to receive(:create)
      do_post
    end
    it "should redirects to the new response_set" do
      do_post
      expect(response).to redirect_to( surveyor.edit_my_survey_path(:survey_code => "alpha", :response_set_code  => "pdq"))
    end

    context "with failures" do
      it "redirect to #new on failed ResponseSet#create" do
        expect(ResponseSet).to receive(:create).and_return(false)
        do_post
        expect(response).to redirect_to(surveyor.available_surveys_path)
      end
      it "redirect to #new on failed Survey#find" do
        do_post :survey_code => "missing"
        expect(response).to redirect_to(surveyor.available_surveys_path)
      end
    end

    context "with javascript check, assigned in session" do
      it "enabled" do
        do_post :surveyor_javascript_enabled => "true"
        expect(session[:surveyor_javascript]).not_to be_nil
        expect(session[:surveyor_javascript]).to eq("enabled")
      end
      it "disabled" do
        post surveyor.take_survey_path(:survey_code => "xyz", :surveyor_javascript_enabled => "not_true" )
        expect(session[:surveyor_javascript]).not_to be_nil
        expect(session[:surveyor_javascript]).to eq("not_enabled")
      end
    end
  end

  context "#show" do
    def do_get(params = {})
      get surveyor.view_my_survey_path({ :survey_code => "alpha", :response_set_code => "pdq" }.merge(params))
    end
    it "renders show" do
      do_get
      expect(response).to be_successful
      expect(response).to render_template('show')
    end
    it "finds ResponseSet with includes" do
      expect(ResponseSet).to receive(:includes).with(:responses => [:question, :answer]).and_return(response_set)
      expect(response_set).to receive(:where).with(:access_code => "pdq").and_return(response_set)
      expect(response_set).to receive(:first).and_return(response_set)
      do_get
    end
    it "redirects for missing response set" do
      do_get :response_set_code => "DIFFERENT"
      expect(response).to redirect_to(surveyor.available_surveys_path)
    end
    it "assigns earlier survey_version" do
      response_set
      do_get
      expect(assigns[:response_set]).to eq(response_set)
      expect(assigns[:survey]).to eq(survey)
    end
    it "assigns later survey_version" do
      response_set_beta
      do_get :response_set_code => "rst"
      expect(assigns[:response_set]).to eq(response_set_beta)
      expect(assigns[:survey]).to eq(survey_beta)
    end
  end

  context "#edit" do
    def do_get(params = {})
      survey.sections = [create(:survey_section, :survey => survey)]
      get surveyor.edit_my_survey_path({ :survey_code => "alpha", :response_set_code => "pdq" }.merge(params))
    end
    it "renders edit and sets start_time" do
      expect(response_set.started_at).to be_nil
      do_get
      expect(response).to be_successful
      expect(response).to render_template('edit')

      response_set.reload
      expect(response_set.started_at).to_not be_nil
    end
    it "should only set start_time the very first time the survey is edited" do
      expect(response_set.started_at).to be_nil
      do_get
      expect(response).to be_successful
      expect(response).to render_template('edit')

      response_set.reload
      expect(response_set.started_at).to_not be_nil
      original_start_time = response_set.started_at

      get surveyor.edit_my_survey_path({ :survey_code => "alpha", :response_set_code => "pdq" })

      expect(response_set.started_at).to eq original_start_time

    end
    it "assigns survey and response set" do
      do_get
      expect(assigns[:survey]).to eq(survey)
      expect(assigns[:response_set]).to eq(response_set)
    end
    it "redirects for missing response set" do
      do_get :response_set_code => "DIFFERENT"
      expect(response).to redirect_to(surveyor.available_surveys_path)
    end
    # it "assigns dependents if javascript not enabled" do
    #   allow(controller).to receive(:get_unanswered_dependencies_minus_section_questions).and_return([create(:question)])
    #   # expect(session[:surveyor_javascript]).to be_nil
    #   do_get
    #   expect(assigns[:dependents]).not_to be_empty
    # end
    # it "does not assign dependents if javascript is enabled" do
    #   allow(controller).to receive(:get_unanswered_dependencies_minus_section_questions).and_return([create(:question)])
    #   # session[:surveyor_javascript] = "enabled"
    #   do_get
    #   expect(assigns[:dependents]).to be_empty
    # end
    it "assigns earlier survey_version" do
      do_get
      expect(assigns[:response_set]).to eq(response_set)
      expect(assigns[:survey]).to eq(survey)
    end
    it "assigns later survey_version" do
      survey_beta.sections = [create(:survey_section, :survey => survey_beta)]
      do_get :response_set_code => "rst"
      expect(assigns[:survey]).to eq(survey_beta)
      expect(assigns[:response_set]).to eq(response_set_beta)

    end
  end

  context "#update" do
    let(:responses_ui_hash) { {} }
    let(:update_params) {
      {
        :survey_code => "alpha",
        :response_set_code => "pdq"
      }
    }
    shared_examples "#update action" do
      before do
        allow(ResponseSet).to receive_message_chain(:includes, :where, :first).and_return(response_set)
        responses_ui_hash['11'] = {'api_id' => 'something', 'answer_id' => '56', 'question_id' => '9'}
      end
      it "saves responses" do
        expect(response_set).to receive(:update_from_ui_hash).with(responses_ui_hash)
        do_put(:r => responses_ui_hash)
      end
      it "does not fail when there are no responses" do
        expect { do_put }.not_to raise_error
      end
      context "with update exceptions" do
        it 'retries the update on a constraint violation' do
          expect(response_set).to receive(:update_from_ui_hash).ordered.with(responses_ui_hash).and_raise(ActiveRecord::StatementInvalid.new('statement invalid'))
          expect(response_set).to receive(:update_from_ui_hash).ordered.with(responses_ui_hash)

          expect { do_put(:r => responses_ui_hash) }.to_not raise_error
        end

        it 'only retries three times' do
          expect(response_set).to receive(:update_from_ui_hash).exactly(3).times.with(responses_ui_hash).and_raise(ActiveRecord::StatementInvalid.new('statement invalid'))

          expect { do_put(:r => responses_ui_hash) }.to raise_error(ActiveRecord::StatementInvalid)
        end

        it 'does not retry for other errors' do
          expect(response_set).to receive(:update_from_ui_hash).once.with(responses_ui_hash).and_raise('Bad news')

          expect { do_put(:r => responses_ui_hash) }.to raise_error('Bad news')
        end
      end
    end

    context "with form submission" do
      def do_put(extra_params = {})
        put edit_my_survey_path(update_params.merge(extra_params))
      end

      it_behaves_like "#update action"
      it "redirects to #edit without params" do
        do_put
        expect(response).to redirect_to(surveyor.edit_my_survey_path(:survey_code => "alpha", :response_set_code => "pdq"))
      end
      it "completes the found response set on finish" do
        do_put :finish => 'finish'
        expect(response_set.reload).to be_complete
      end
      it 'flashes completion' do
        do_put :finish => 'finish'
        expect(flash[:notice]).to eq("Completed survey")
      end
      it "redirects for missing response set" do
        do_put :response_set_code => "DIFFERENT"
        expect(response).to redirect_to(surveyor.available_surveys_path)
        expect(flash[:notice]).to eq("Unable to find your responses to the survey")
      end
    end

    context 'with ajax' do
      def do_put(extra_params = {})
        put surveyor.edit_my_survey_path(update_params.merge(extra_params)), xhr: true
      end

      it_behaves_like "#update action"
      it "returns dependencies" do
        allow(ResponseSet).to receive_message_chain(:includes, :where, :first).and_return(response_set)
        expect(response_set).to receive(:all_dependencies).and_return({"show" => ['q_1'], "hide" => ['q_2']})

        do_put
        expect(JSON.parse(response.body)).to eq({"show" => ['q_1'], "hide" => ["q_2"]})
      end
      it "returns 404 for missing response set" do
        do_put :response_set_code => "DIFFERENT"
        expect(response.status).to eq(404)
      end
    end
  end

  context "#export" do
    # render_views

    let(:json) {
      get surveyor.export_survey_path(:survey_code => survey.access_code, :format => 'json' )
      JSON.parse(response.body)
    }

    context "question inside and outside a question group" do
      def question_text(refid)
        <<-SURVEY
          q "Where is a foo?", :pick => :one, :help_text => 'Look around.', :reference_identifier => #{refid.inspect},
            :data_export_identifier => 'X.FOO', :common_namespace => 'F', :common_identifier => 'f'
          a_L 'To the left', :data_export_identifier => 'X.L', :common_namespace => 'F', :common_identifier => 'l'
          a_R 'To the right', :data_export_identifier => 'X.R', :common_namespace => 'F', :common_identifier => 'r'
          a_O 'Elsewhere', :string

          dependency :rule => 'R'
          condition_R :q_bar, "==", :a_1
        SURVEY
      end
      let(:survey_text) {
        <<-SURVEY
          survey 'xyz' do
            section 'Sole' do
              q_bar "Should that other question show up?", :pick => :one
              a_1 'Yes'
              a_2 'No'

              #{question_text('foo_solo')}

              group do
                #{question_text('foo_grouped')}
              end
            end
          end
        SURVEY
      }
      let(:survey) { Surveyor::Parser.new.parse(survey_text) }
      let(:solo_question_json)    { json['sections'][0]['questions_and_groups'][1] }
      let(:grouped_question_json) { json['sections'][0]['questions_and_groups'][2]['questions'][0] }

      it "produces identical JSON except for API IDs and question reference identifers" do
        expect(solo_question_json['answers'].to_json).to be_json_eql( grouped_question_json['answers'].to_json).excluding("uuid", "reference_identifier")
        expect(solo_question_json['dependency'].to_json).to be_json_eql( grouped_question_json['dependency'].to_json).excluding("uuid", "reference_identifier")
        expect(solo_question_json.to_json).to be_json_eql( grouped_question_json.to_json).excluding("uuid", "reference_identifier")
      end
      it "produces the expected reference identifier for the solo question" do
        expect(solo_question_json['reference_identifier']).to eq('foo_solo')
      end
      it "produces the expected reference identifer for the question in the group" do
        expect(grouped_question_json['reference_identifier']).to eq('foo_grouped')
      end
    end
  end
end
