class Response < ApplicationRecord
  include ActionView::Helpers::SanitizeHelper
  include Surveyor::Models::ResponseMethods
end
