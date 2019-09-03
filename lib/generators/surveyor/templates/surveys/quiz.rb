# encoding: UTF-8
survey "Favorites" do
  section "Foods" do
    # In a quiz, both the questions and the answers need to have reference identifiers
    # Here, the question has reference_identifier: "1", and the answers: "oint", "tweet", and "moo"
    # Since "oink" is the correct answer a weight of 1 is added for that answer..note the double underscore!!
    question_1 "What is the best meat?", :pick => :one, :correct => "oink"
    a_oink__1 "bacon"
    a_tweet "chicken"
    a_moo "beef"
  end
end