require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/surveyor/helpers/formtastic_custom_input')

describe Surveyor::Helpers::FormtasticCustomInput do
  context "input helpers" do
    it "should translate response class into attribute" do
      expect(helper.response_class_to_method(:string)).to eq(:string_value)
      expect(helper.response_class_to_method(:integer)).to eq(:integer_value)
      expect(helper.response_class_to_method(:float)).to eq(:float_value)
      expect(helper.response_class_to_method(:datetime)).to eq(:datetime_value)
      expect(helper.response_class_to_method(:date)).to eq(:date_value)
      expect(helper.response_class_to_method(:time)).to eq(:time_value)
    end
  end
end