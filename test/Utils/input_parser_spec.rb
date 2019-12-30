require "minitest/autorun"
require_relative "../../lib/Utils/input_parser"

describe InputParser do
  include InputParser

  it "Command is invalid" do
    assert_equal "OK",validate_command("set test1 124 0 3")
  end

  it "Command name is invalid" do
    assert_equal "ERROR",validate_command("adding test1 124 0 3")
  end

  it "Number of parameters less than minimum" do
    assert_equal "ERROR",validate_command("set test1 124 3")
  end

  it "Number of parameters more than maximum" do
    assert_equal "ERROR",validate_command("set test1 124 3 4 three asd")
  end

  it "The flag is not a number" do
    assert_equal "CLIENT_ERROR bad command line format",validate_command("set test1 test 124 3")
  end

  it "The time is not a number" do
    assert_equal "CLIENT_ERROR bad command line format",validate_command("set test1 4 test 3")
  end

  it "The flag length is longer than 16 bits" do
    assert_equal "CLIENT_ERROR bad command line format",validate_command("set key 999999999999 5 3")
  end

  it "The data lengths does match" do
    assert_equal "OK", validate_data("set test1 124 0 3","abc")
  end

  it "The data lengths does not match" do
    assert_equal "CLIENT_ERROR bad data chunk", validate_data("set test1 124 0 3","abcde")
  end

end
