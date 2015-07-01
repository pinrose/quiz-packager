require "spec_helper"

describe QuizPackager do

  describe "package" do

    before(:all) do
      QuizPackager.package("http://localhost:3000/quiz/nordstrom?embed=1")
    end

    it "creates output directory" do
      expect(Dir).to exist("./output")
    end

    it "creates index file" do
      expect(File).to exist("./output/index.html")
    end

    it "downloads image assets" do
      expect(Dir).to exist("./output/images/assets")
    end

    it "downloads javascript assets" do
      expect(Dir).to exist("./output/js/assets")
    end

    it "downloads css assets" do
      expect(Dir).to exist("./output/css/assets")
    end
  end
end
