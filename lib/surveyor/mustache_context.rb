module Surveyor
  module MustacheContext
    extend ActiveSupport::Concern

    def in_context(text, context=nil)
      return unless text.present?

      if context.is_a?(NilClass)
        text
      elsif context.is_a?(Hash)
        Mustache.render(text, context)
      else
        context.render(text)
      end
    end
  end
end