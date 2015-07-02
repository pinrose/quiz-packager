require "quiz_packager/version"
require "quiz_packager/remote_document"

class QuizPackager
  def self.package(url, path)
    doc = RemoteDocument.new URI(url)
    doc.exclude_resources = ["Video.mp4"]
    doc.mirror(path)
  end
end
