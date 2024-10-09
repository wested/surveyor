require 'rails'
require 'haml' # required for view resolution
require 'sprockets/railtie'
require 'surveyor'

module Surveyor
  class Engine < Rails::Engine
    config.autoload_paths << File.join(config.root, "lib")
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
