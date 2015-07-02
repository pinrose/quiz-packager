require "quiz_packager/version"
require "quiz_packager/remote_document"

class QuizPackager
  def self.package(url)
    uri = URI(url)
    path = "./output/index.html"
    doc = RemoteDocument.new(uri)
    # doc.exclude_resources = ['facebook.com', 'cloudflare.com', 'jsdelivr.net', 'bootstrapcdn.com', 'liquid_assets']
    doc.mirror(path)
  end
end
