require "spec_helper"

describe QuizPackager do
  subject { QuizPackager.new }

  describe "#package" do
    let(:url) { "localhost:3000/quiz/nordstrom?embed=1" }

    before do
      subject.package(url)
    end

    it "creates output directory" do
      expect(Dir).to exist("./output")
    end
  end
end
