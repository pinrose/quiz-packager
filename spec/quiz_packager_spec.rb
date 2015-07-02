require "spec_helper"

describe QuizPackager do

  describe "package" do

    before(:all) do
      QuizPackager.package("http://localhost:3000/quiz/nordstrom?embed=1", "./output/index.html")
    end

    it "creates output directory" do
      expect(Dir).to exist("./output")
    end

    it "creates index file" do
      expect(File).to exist("./output/index.html")
    end

    it "downloads assets" do
      expect(Dir).to exist("./output/assets")
    end
  end
end
