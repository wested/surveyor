require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ValidationCondition do
  before(:each) do
    @validation_condition = FactoryGirl.create(:validation_condition)
  end

  it "should be valid" do
     expect(@validation_condition).to be_valid
  end
  # this causes issues with building and saving
  # it "should be invalid without a parent validation_id" do
  #   @validation_condition.validation_id = nil
  #   @validation_condition.should have(1).errors_on(:validation_id)
  # end

  it "should be invalid without an operator" do
    @validation_condition.operator = nil
    @validation_condition.valid?
    expect(@validation_condition.errors[:operator].size).to eq(2)
  end

  it "should be invalid without a rule_key" do
    expect(@validation_condition).to be_valid
    @validation_condition.rule_key = nil
    expect(@validation_condition).not_to be_valid
    @validation_condition.valid?
    expect(@validation_condition.errors[:rule_key].size).to eq(1)
  end

  it "should have unique rule_key within the context of a validation" do
   expect(@validation_condition).to be_valid
   FactoryGirl.create(:validation_condition, :validation_id => 2, :rule_key => "2")
   @validation_condition.rule_key = "2" #rule key uniquness is scoped by validation_id
   @validation_condition.validation_id = 2
   @validation_condition.valid?
   expect(@validation_condition).not_to be_valid
   expect(@validation_condition.errors[:rule_key].size).to eq(1)
  end

  it "should have an operator in Surveyor::Common::OPERATORS" do
    Surveyor::Common::OPERATORS.each do |o|
      @validation_condition.operator = o
      @validation_condition.valid?
      expect(@validation_condition.errors[:operator].size).to eq(0)
    end
    @validation_condition.operator = "#"
    @validation_condition.valid?
    expect(@validation_condition.errors[:operator].size).to eq(1)
  end
end

describe ValidationCondition, "validating responses" do
  def test_var(vhash, ahash, rhash)
    v = FactoryGirl.create(:validation_condition, vhash)
    a = FactoryGirl.create(:answer, ahash)
    r = FactoryGirl.create(:response, {:answer => a, :question => a.question}.merge(rhash))
    return v.is_valid?(r)
  end

  it "should validate a response by regexp" do
    expect(test_var({:operator => "=~", :regexp => /^[a-z]{1,6}$/.to_s}, {:response_class => "string"}, {:string_value => "clear"})).to be_truthy
    expect(test_var({:operator => "=~", :regexp => /^[a-z]{1,6}$/.to_s}, {:response_class => "string"}, {:string_value => "foobarbaz"})).to be_falsey
  end
  it "should validate a response by integer comparison" do
    expect(test_var({:operator => ">", :integer_value => 3}, {:response_class => "integer"}, {:integer_value => 4})).to be_truthy
    expect(test_var({:operator => "<=", :integer_value => 256}, {:response_class => "integer"}, {:integer_value => 512})).to be_falsey
  end
  it "should validate a response by (in)equality" do
    expect(test_var({:operator => "!=", :datetime_value => Date.today + 1}, {:response_class => "date"}, {:datetime_value => Date.today})).to be_truthy
    expect(test_var({:operator => "==", :string_value => "foo"}, {:response_class => "string"}, {:string_value => "foo"})).to be_truthy
  end
  it "should represent itself as a hash" do
    @v = FactoryGirl.create(:validation_condition, :rule_key => "A")
    allow(@v).to receive(:is_valid?).and_return(true)
    expect(@v.to_hash("foo")).to eq({:A => true})
    allow(@v).to receive(:is_valid?).and_return(false)
    expect(@v.to_hash("foo")).to eq({:A => false})
  end
end

describe ValidationCondition, "validating responses by other responses" do
  def test_var(v_hash, a_hash, r_hash, ca_hash, cr_hash)
    ca = FactoryGirl.create(:answer, ca_hash)
    cr = FactoryGirl.create(:response, cr_hash.merge(:answer => ca, :question => ca.question))
    v = FactoryGirl.create(:validation_condition, v_hash.merge({:question_id => ca.question.id, :answer_id => ca.id}))
    a = FactoryGirl.create(:answer, a_hash)
    r = FactoryGirl.create(:response, r_hash.merge(:answer => a, :question => a.question))
    return v.is_valid?(r)
  end
  it "should validate a response by integer comparison" do
    expect(test_var({:operator => ">"}, {:response_class => "integer"}, {:integer_value => 4}, {:response_class => "integer"}, {:integer_value => 3})).to be_truthy
    expect(test_var({:operator => "<="}, {:response_class => "integer"}, {:integer_value => 512}, {:response_class => "integer"}, {:integer_value => 4})).to be_falsey
  end
  it "should validate a response by (in)equality" do
    expect(test_var({:operator => "!="}, {:response_class => "date"}, {:datetime_value => Date.today}, {:response_class => "date"}, {:datetime_value => Date.today + 1})).to be_truthy
    expect(test_var({:operator => "=="}, {:response_class => "string"}, {:string_value => "donuts"}, {:response_class => "string"}, {:string_value => "donuts"})).to be_truthy
  end
  it "should not validate a response by regexp" do
    expect(test_var({:operator => "=~"}, {:response_class => "date"}, {:datetime_value => Date.today}, {:response_class => "date"}, {:datetime_value => Date.today + 1})).to be_falsey
    expect(test_var({:operator => "=~"}, {:response_class => "string"}, {:string_value => "donuts"}, {:response_class => "string"}, {:string_value => "donuts"})).to be_falsey
  end
end
