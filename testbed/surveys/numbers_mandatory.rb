survey "Numbers Mandatory", default_mandatory: true do
  section "Addition" do
    q_1 "What is one plus one?", pick: :one, correct: "2"
    a_1__4 "1"
    a_2__3 "2"
    a_3__2 "3"
    a_4_out__1 "4"

    q_2 "What is five plus one?", pick: :one, correct: "6"
    a_5 "five"
    a_6 "six"
    a_7 "seven"
    a_8 "eight"
  end
  section "Literature" do
    q_the_answer "What is the 'Answer to the Ultimate Question of Life, The Universe, and Everything'", pick: :one, correct: "adams"
    a_pi "3.14"
    a_zero "0"
    a_adams "42"
  end
end