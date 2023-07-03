# encoding: UTF-8
class UpdateBlankApiIdsOnQuestionGroup < ActiveRecord::Migration[4.2]
  def self.up
    check = [Survey, Question, QuestionGroup, Answer, Response, ResponseSet]
    check.each do |clazz|
      clazz.where('api_id IS ?', nil).each do |c|
        c.api_id = Surveyor::Common.generate_api_id
        c.save!
      end
    end
  end

  def self.down
  end
end
