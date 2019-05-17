# encoding: utf-8
# http://github.com/thoughtbot/factory_girl/tree/master
require 'rubygems'
require 'factory_bot'

FactoryBot.define do

  sequence(:unique_survey_access_code){|n| "simple survey #{UUIDTools::UUID.random_create.to_s}" }

  factory :survey do
    title           { "Simple survey" }
    description     { "A simple survey for testing" }
    access_code     { generate :unique_survey_access_code }
    survey_version  { 0 }
  end


  factory :survey_translation do
    locale { "es" }
    translation { %(title: "Un idioma nunca es suficiente"
      survey_sections:
        one:
          title: "Uno"
      questions:
        hello:
          text: "¡Hola!"
        name:
          text: "¿Cómo se llama Usted?"
          answers:
            name:
              help_text: "Mi nombre e..") }
  end

  sequence(:survey_section_display_order) {|n| n }

  factory :survey_section do
    association               :survey  # survey_id                 {}
    title                     {"Demographics"}
    description               {"Asking you about your personal data"}
    display_order             {generate :survey_section_display_order}
    reference_identifier      {"demographics"}
    data_export_identifier    {"demographics"}
  end

  sequence(:question_display_order){|n| n }

  factory :question do
    association             :survey_section   # survey_section_id       {}
    # question_group_id       {}
    text                    { "What is your favorite color?" }
    short_text              { "favorite_color" }
    help_text               { "just write it in the box" }
    pick                    { :none }
    reference_identifier    {|me| "q_#{me.object_id}"}
    # data_export_identifier  {}
    # common_namespace        {}
    # common_identifier       {}
    display_order           { generate(:question_display_order) }
    # display_type            {} # nil is default
    is_mandatory            { false }
    # display_width           {}
    correct_answer_id       { nil }
  end

  factory :question_group do
    text                    {"Describe your family"}
    help_text               {}
    reference_identifier    {|me| "g_#{me.object_id}"}
    data_export_identifier  {}
    common_namespace        {}
    common_identifier       {}
    display_type            {}
    custom_class            {}
    custom_renderer         {}
  end

  sequence(:answer_display_order) {|n| n }

  factory :answer do
    association               :question   # question_id               {}
    text                      { "My favorite color is clear" }
    short_text                { "clear" }
    help_text                 { "Clear is the absense of color" }
    # weight
    response_class            { "string" }
    # reference_identifier      {}
    # data_export_identifier    {}
    # common_namespace          {}
    # common_identifier         {}
    display_order             {generate :answer_display_order}
    # is_exclusive              {}
    display_type              { "default" }
    # display_length            {}
    # custom_class              {}
    # custom_renderer           {}
  end

  factory :dependency do
    # the dependent question
    association       :question # question_id       {}
    question_group_id {}
    rule              {"A"}
  end

  factory :dependency_condition do
    association       :dependency  # dependency_id    {}
    rule_key          {"A"}
    # the conditional question
    question_id       {}
    operator          {"=="}
    answer_id         {}
    datetime_value    {}
    integer_value     {}
    float_value       {}
    unit              {}
    text_value        {}
    string_value      {}
    response_other    {}
  end

  factory :response_set do
    user_id         {}
    association     :survey  # survey_id       {}
    access_code     {Surveyor::Common.make_tiny_code}
    started_at      {Time.now}
    completed_at    {}
  end

  factory :response do
    association       :response_set  # response_set_id   {}
    survey_section_id {}
    question_id       {}
    answer_id         {}
    datetime_value    {}
    integer_value     {}
    float_value       {}
    unit              {}
    text_value        {}
    string_value      {}
    response_other    {}
    response_group    {}
  end

  factory :validation do
    association       :answer # answer_id         {}
    rule              {"A"}
    message           {}
  end

  factory :validation_condition do
    association       :validation  # validation_id     {}
    rule_key          {"A"}
    question_id       {}
    operator          {"=="}
    answer_id         {}
    datetime_value    {}
    integer_value     {}
    float_value       {}
    unit              {}
    text_value        {}
    string_value      {}
    response_other    {}
    regexp            {}
  end

end
