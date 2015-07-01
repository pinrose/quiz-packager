require "quiz_packager/version"
require "quiz_packager/remote_document"

class QuizPackager
  def package(url)
    uri = URI(url)
    path = "./output/index.html"
    RemoteDocument.new(uri).mirror(path)
  end
end
