require "surveyor/version"
require "surveyor/engine"
require "surveyor/common"
require "surveyor/acts_as_response"
require "formtastic"

module Surveyor
end

Formtastic::FormBuilder.default_text_area_height = 5
Formtastic::FormBuilder.default_text_area_width = 50
Formtastic::FormBuilder.all_fields_required_by_default = false
Formtastic::FormBuilder.input_class_finder = Formtastic::InputClassFinder
Formtastic::FormBuilder.action_class_finder = Formtastic::ActionClassFinder
