require "quiz_packager/version"
require "quiz_packager/remote_document"
require "quiz_packager/zip_file_generator"

class QuizPackager
  attr_reader :uri
  attr_reader :path

  def initialize(url, path)
    @uri = URI(url)
    @path = path
  end

  def package
    clean_path
    doc = RemoteDocument.new uri
    doc.search_resources = [/quiz\S*.css/, /quiz\S*.js/]
    doc.exclude_resources = [/quiz-content\S*.zip/]
    doc.mirror(path)
    create_zip_file
  end

  def clean_path
    FileUtils.rm_rf Dir.glob("#{base_dir}/*")
  end

  def base_dir
    File.dirname path
  end

  def create_zip_file
    output_file = File.join(base_dir, "quiz-content.zip")
    ZipFileGenerator.new(base_dir, output_file).write
  end
end
