require 'rabl'
Rabl.register!
Rabl.configure {|config| config.include_child_root = false }
Rabl.configure {|config| config.include_json_root = false }
module Surveyor
  module SurveyorControllerMethods
    extend ActiveSupport::Concern
    included do
      include SurveyorHelper

      before_action :get_current_user, :only => [:new, :create]
      before_action :determine_if_javascript_is_enabled, :only => [:create, :update]
      before_action :set_response_set_and_render_context, :only => [:edit, :show]

      layout 'surveyor_default'
      before_action :set_locale
    end

    # Actions
    def index
      @surveys_by_access_code = Survey.order("created_at DESC, survey_version DESC").to_a.group_by(&:access_code)
      redirect_to surveyor_index unless surveyor_index == surveyor.available_surveys_path
    end

    def new
      create
    end

    def create
      set_survey

      @response_set = ResponseSet.
        create(:survey => @survey, :user_id => (@current_user.nil? ? @current_user : @current_user.id))
      if (@survey && @response_set)
        flash[:notice] = t('surveyor.survey_started_success')
        redirect_to(surveyor.edit_my_survey_path(
          :survey_code => @survey.access_code, :response_set_code  => @response_set.access_code))
      else
        flash[:notice] = t('surveyor.Unable_to_find_that_survey')
        redirect_to surveyor.available_surveys_path
      end
    end

    def show
      # @response_set is set in before_filter - set_response_set_and_render_context
      if @response_set
        @survey = @response_set.survey
        respond_to do |format|
          format.html #{render :action => :show}
          format.csv {
            send_data(@response_set.to_csv, :type => 'text/csv; charset=utf-8; header=present',
              :filename => "#{@response_set.updated_at.strftime('%Y-%m-%d')}_#{@response_set.access_code}.csv")
          }
          format.json
        end
      else
        flash[:notice] = t('surveyor.unable_to_find_your_responses')
        redirect_to surveyor_index
      end
    end

    def edit
      # @response_set is set in before_filter - set_response_set_and_render_context
      if @response_set
        @sections = SurveySection.where(survey_id: @response_set.survey_id).includes([:survey, {questions: [{answers: :question}, {question_group: :dependency}, :dependency]}])
        @section = (section_id_from(params) ? @sections.where(id: section_id_from(params)).first : @sections.first) || @sections.first
        @survey = @section.survey
        set_dependents
        @response_set.ensure_start_timestamp!
      else
        flash[:notice] = t('surveyor.unable_to_find_your_responses')
        redirect_to surveyor_index
      end
    end

    def update
      question_ids_for_dependencies = (params[:r].try(:values) || []).map{|v| v["question_id"] }.compact.uniq
      saved = load_and_update_response_set_with_retries

      if saved && params[:finish] && !@response_set.mandatory_questions_complete?
        #did not complete mandatory fields
        ids, remove, question_ids, flashmsg = {}, {}, [], []
        flashmsg << "<p> #{t('surveyor.mandatory_error_msg')} </p>"

        triggered_mandatory_missing = @response_set.triggered_mandatory_missing

        survey_section = ''
        question_number = {}
        last_question_of_previous_section = 0
        last_question_number = 0
        @response_set.survey.sections.each do |ss|
          index = 0
          ss.questions.where('display_type!=?','label').each do |q|
            if q.triggered?(@response_set)
              question_number[q.id.to_s] = last_question_number = last_question_of_previous_section + index + 1
              index = index + 1
            end
          end
          last_question_of_previous_section = last_question_number
        end

        triggered_mandatory_missing.each_with_index do |m, i|
          if m.survey_section != survey_section
            flashmsg << "</ul>" if i > 0

            survey_section = m.survey_section
            flashmsg << "<div class='survey_section'><h4 class='title'> #{m.survey_section.title}</h4></div> <ul>"
          end

          flashmsg << mandatory_question_error(params[:response_set_code], m)
        end
        respond_to do |format|
          format.js do

            render :json=>{"flashmsg"=>flashmsg}
          end
          format.html do
            flash.now[:danger] = flashmsg.join('')
            edit
            render :edit
          end
        end
        return
      elsif saved && params[:finish]
        return redirect_with_message(surveyor_finish, :notice, t('surveyor.completed_survey'))
      end


      respond_to do |format|
        format.html do
          if @response_set.nil?
            return redirect_with_message(surveyor.available_surveys_path, :notice, t('surveyor.unable_to_find_your_responses'))
          else
            flash[:notice] = t('surveyor.unable_to_update_survey') unless saved
            redirect_to surveyor.edit_my_survey_path(:anchor => anchor_from(params[:section]), :section => section_id_from(params))
          end
        end
        format.js do
          if @response_set
            render :json => @response_set.reload.all_dependencies(question_ids_for_dependencies)
          else
            render plain: "No response set #{params[:response_set_code]}",
                   :status => 404
          end
        end
      end
    end

    def load_and_update_response_set_with_retries(remaining=2)
      begin
        load_and_update_response_set
      rescue ActiveRecord::StatementInvalid => e
        if remaining > 0
          load_and_update_response_set_with_retries(remaining - 1)
        else
          raise e
        end
      end
    end

    def load_and_update_response_set
      ResponseSet.transaction do
        @response_set = ResponseSet.includes({:responses => :answer}).where(:access_code => params[:response_set_code]).first
        if @response_set
          saved = true
          if params[:r]
            @response_set.update_from_ui_hash(params[:r])
          end
          if params[:finish] && @response_set.mandatory_questions_complete?
            @response_set.complete!
            saved &= @response_set.save
          end
          saved
        else
          false
        end
      end
    end
    private :load_and_update_response_set

    def export
      surveys = Survey.where(:access_code => params[:survey_code]).order("survey_version DESC")
      s = params[:survey_version].blank? ? surveys.first : surveys.where(:survey_version => params[:survey_version]).first
      render_404 and return if s.blank?
      @survey = s.filtered_for_json
    end

    def render_404
      head 404
      true
    end

    def url_options
      ((I18n.locale == I18n.default_locale) ? {} : {:locale => I18n.locale}).merge(super)
    end

    private

    # This is a hook method for surveyor-using applications to override and provide the context object
    def render_context
      nil
    end

    # Filters
    def get_current_user
      @current_user = self.respond_to?(:current_user) ? self.current_user : nil
    end

    def set_response_set_and_render_context
      @response_set = ResponseSet.includes({:responses => [:question, :answer]}).where(:access_code => params[:response_set_code]).first
      @render_context = render_context
    end

     def set_locale
      if params[:new_locale]
        I18n.locale = params[:new_locale]
      elsif params[:locale]
        I18n.locale = params[:locale]
      else
        I18n.locale = I18n.default_locale
      end
    end

    # Params: the name of some submit buttons store the section we'd like to go
    # to. for repeater questions, an anchor to the repeater group is also stored
    # e.g. params[:section] = {"1"=>{"question_group_1"=>"<= add row"}}
    def section_id_from(p = {})
      if p[:section] && p[:section].respond_to?(:keys)
        p[:section].keys.first
      elsif p[:section]
        p[:section]
      elsif p[:current_section]
        p[:current_section]
      end
    end

    def anchor_from(p)
      p.respond_to?(:keys) && p[p.keys.first].respond_to?(:keys) ? p[p.keys.first].keys.first : nil
    end

    def surveyor_index
      surveyor.available_surveys_path
    end
    def surveyor_finish
      surveyor.available_surveys_path
    end

    def redirect_with_message(path, message_type, message)
      respond_to do |format|
        format.html do
          flash[message_type] = message if !message.blank? and !message_type.blank?
          redirect_to path
        end
        format.js do
          render :text => message, :status => 403
        end
      end
    end

    ##
    # @dependents are necessary in case the client does not have javascript enabled
    # Whether or not javascript is enabled is determined by a hidden field set in the surveyor/edit.html form
    def set_dependents
      if session[:surveyor_javascript] && session[:surveyor_javascript] == "enabled"
        @dependents = []
      else
        @dependents = get_unanswered_dependencies_minus_section_questions
      end
    end

    def get_unanswered_dependencies_minus_section_questions
      @response_set.unanswered_dependencies - @section.questions || []
    end

    ##
    # If the hidden field surveyor_javascript_enabled is set to true
    # cf. surveyor/edit.html.haml
    # the set the session variable [:surveyor_javascript] to "enabled"
    def determine_if_javascript_is_enabled
      if params[:surveyor_javascript_enabled] && params[:surveyor_javascript_enabled].to_s == "true"
        session[:surveyor_javascript] = "enabled"
      else
        session[:surveyor_javascript] = "not_enabled"
      end
    end

    def set_survey
      surveys = Survey.where(:access_code => params[:survey_code]).order("survey_version DESC")
      if params[:survey_version].blank?
        @survey = surveys.first
      else
        @survey = surveys.where(:survey_version => params[:survey_version]).first
      end
    end
  end
end
