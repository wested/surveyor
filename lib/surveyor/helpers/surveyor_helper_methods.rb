module Surveyor
  module Helpers
    module SurveyorHelperMethods

      # Layout: stylsheets and javascripts
      def surveyor_includes
        stylesheet_link_tag('surveyor_all') + javascript_include_tag('surveyor_all')
      end

      # Helper for displaying warning/notice/error flash messages
      def flash_messages(types)
        types.map{|type| content_tag(:div, "#{flash[type]}".html_safe, :class => "alert alert-#{type.to_s}")}.join.html_safe
      end

      def mandatory_question_error(response_set_code, question)
        question_text = Loofah.fragment(question.text).to_text

        "<li class='question-error'> <a href='#{surveyor.edit_my_survey_path(response_set_code, section: question.survey_section_id)}#q_#{question.id}'> #{question_text.truncate(100)}</a> </li>"
      end

      # Section: dependencies, menu, previous and next
      def dependency_explanation_helper(question,response_set)
        # Attempts to explain why this dependent question needs to be answered by referenced the dependent question and users response
        trigger_responses = []
        dependent_questions = Question.find_all_by_id(question.dependency.dependency_conditions.map(&:question_id)).uniq
        response_set.responses.find_all_by_question_id(dependent_questions.map(&:id)).uniq.each do |resp|
          trigger_responses << resp.to_s
        end
        "&nbsp;&nbsp;You answered &quot;#{trigger_responses.join("&quot; and &quot;")}&quot; to the question &quot;#{dependent_questions.map(&:text).join("&quot;,&quot;")}&quot;"
      end
      def menu_button_for(section)
        button_tag(section.translation(I18n.locale)[:title], :name => "section[#{section.id}]", type: 'submit', class: 'section-submit')
      end
      def previous_section
        # use copy in memory instead of making extra db calls
        prev_index = [(@sections.index(@section) || 0) - 1, 0].max
        submit_tag(t('surveyor.previous_section').html_safe, :name => "section[#{@sections[prev_index].id}]") unless @sections[0] == @section
      end
      def next_section
        # use copy in memory instead of making extra db calls
        next_index = [(@sections.index(@section) || @sections.count) + 1, @sections.count].min
        @sections.last == @section ? submit_tag(t('surveyor.click_here_to_finish').html_safe, :name => "finish") : submit_tag(t('surveyor.next_section').html_safe, :name => "section[#{@sections[next_index].id}]")
      end

      def save_section
        submit_tag(t('surveyor.save_section').html_safe, :name => "section[#{@section.id}]")
      end

      def section_last_updated_at(section)
        survey_section_question_ids = section.questions.map(&:id)
        last_updated_question = @response_set.responses.where(question: survey_section_question_ids).select('MAX(updated_at) updated_at').first

        last_updated_question.try(:updated_at)
      end

      # Questions
      def question_group_text(question_number, text)
        if question_number.present?
          question_number_with_text(question_number, text)
        else
          text
        end
      end

      def q_text(q, context=nil, locale=nil)
        if q.dependent? or q.display_type == "label" or q.display_type == "image" or q.part_of_group?
          q.text_for(nil, context, locale)
        else
          question_number = next_question_number(q)
          question_number = "<span class='required-asterisk'>*</span>" + question_number if q.is_mandatory
          question_number_with_text(question_number, q.text_for(nil, context, locale))
        end
      end

      def next_question_number(question)
        @n ||= 0
        "<span class='qnum'>#{@n += 1}) </span>"
      end

      def question_number_with_text(question_number, text)
        "<div class='question'>#{question_number}#{text}</div>"
      end

      # Responses
      def rc_to_attr(type_sym)
        case type_sym.to_s
        when /^answer$/ then :answer_id
        else "#{type_sym.to_s}_value".to_sym
        end
      end

      def rc_to_as(type_sym)
        case type_sym.to_s
        when /(integer|float|date|time|datetime)/ then :string
        else type_sym
        end
      end

      def generate_pick_none_input_html(value, default_value, css_class, response_class, disabled, input_mask, input_mask_placeholder)
        html = {}
        html[:class] = [response_class,css_class].reject{ |c| c.blank? }
        html[:value] = value.blank? ? default_value : value
        html[:disabled] = disabled unless disabled.blank?
        if input_mask
          html[:'data-input-mask'] = input_mask
          html[:'data-input-mask-placeholder'] = input_mask_placeholder unless input_mask_placeholder.blank?
        end
        html
      end

      # Responses
      def response_for(response_set, question, answer = nil, response_group = nil)
        return nil unless response_set && question && question.id
        result = response_set.responses.detect{|r| (r.question_id == question.id) && (answer.blank? ? true : r.answer_id == answer.id) && (r.response_group.blank? ? true : r.response_group.to_i == response_group.to_i)}
        result.blank? ? response_set.responses.build(:question_id => question.id, :response_group => response_group) : result
      end
      def response_idx(increment = true)
        @rc ||= 0
        (increment ? @rc += 1 : @rc).to_s
      end

      # Answers
      def choice_answer_wrapper(text)
        "<span> #{text} </span>".html_safe
      end
    end
  end
end
