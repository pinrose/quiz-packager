require "quiz_packager/version"
require "quiz_packager/remote_document"

class QuizPackager
  class << self
    def package(url, path)
      clean path
      doc = RemoteDocument.new URI(url)
      doc.exclude_resources = ["Video.mp4"]
      doc.mirror(path)
    end

    def clean(path)
      dir = File.dirname path
      FileUtils.rm_rf(Dir.glob("#{dir}/*"))
    end
  end
end
