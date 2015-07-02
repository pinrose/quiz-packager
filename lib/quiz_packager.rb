require "quiz_packager/version"
require "quiz_packager/remote_document"

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
    doc.search_resources = ['quiz/base.css', 'quiz-nordstrom.css', 'quiz.js']
    doc.mirror(path)
    move_audio_files
  end

  def clean_path
    FileUtils.rm_rf Dir.glob("#{base_dir}/*")
  end

  def move_audio_files
    audio_dir = File.join(base_dir, "assets/quiz/audio")
    FileUtils.mv(audio_dir, base_dir, force: true) if Dir.exists? audio_dir
  end

  def base_dir
    File.dirname path
  end
end
