require 'rails'
require 'surveyor'
require 'haml' # required for view resolution

module Surveyor
  class Engine < Rails::Engine

    root = File.expand_path('../../', __FILE__)
    config.autoload_paths << root
    config.to_prepare do
      Dir.glob(File.expand_path('../../../app/inputs/*_input*.rb', __FILE__)).each do |c|
        require_dependency(c)
      end
    end
  end

  mattr_accessor :save_section

  def save_section
    @save_section.present? ? @save_section : false
  end

  # self.save_section = false

  # class << self
  #   mattr_accessor :save_section
  #
  #   # add default values of more config vars here
  #   self.save_section = false
  #
  # end

  # this function maps the vars from your app into your engine
  def self.setup(&block)
    yield self
  end
end
