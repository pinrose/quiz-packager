require "spec_helper"

describe QuizPackager do

  describe "package" do

    before(:all) do
      QuizPackager.new("http://staging.pinrose.com/quiz/nordstrom?embed=1", "./output/index.html").package
    end

    it "creates output directory" do
      expect(Dir).to exist("./output")
    end

    it "creates zip package" do
      expect(File).to exist("./output/quiz-content.zip")
    end
  end
end
