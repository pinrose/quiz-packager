require "net/http"
require "uri"
require "fileutils"
require "logger"
require "pathname"
require "yaml"

class RemoteDocument
  attr_reader :uri
  attr_reader :contents
  attr_reader :resources
  attr_accessor :exclude_resources
  attr_accessor :search_resources

  def initialize(uri)
    @uri = uri
    @exclude_resources = []
    @search_resources = []
  end

  def mirror(path)
    logger.info "Mirroring #{uri} to #{path}"
    load_contents
    find_resources
    save_locally path
  end

private

  def load_contents
    @contents = http_get uri
  end

  def find_resources
    @resources = (
      find_urls + 
      find_relative_paths +
      find_network_paths
    ).uniq
      .select{ |u| has_extension?(u) }
      .reject{ |u| excluded_resource?(u) }
  end

  def find_urls
    # Extract absolute URLs
    URI.extract(@contents, ["http", "https"])
      .map{ |u| u.gsub(/[\),']*$/, "") }          # Trim invalid characters from end of URL
  end

  def find_relative_paths
    # e.g. '/assets/example.jpg'
    @contents.scan(/(?<=["'(])\/[^"')\s\\]+/).flatten
  end

  def find_network_paths
    # e.g. '//example.com/script.js'
    @contents.scan(/(?<=["'])\/\/[^"'\s\\]+/).flatten
  end

  # Create a local path from a URL
  def localize_url(url, dir)
    path = url.gsub(/^[|[:alpha]]+:\/\//, "")
    path.gsub!(/^[.\/]+/, "")
    path.gsub!(/\?.*/, "")                      # Remove query string
    path.gsub!(/(.*[.:]+.*?)(?=\/)/, '_\1')     # Prefix domain names with underscore
    path.gsub!(/:\/|:/, "")                     # Remove ':/' or ':'
    File.join(dir, path)
  end

  def url_for(str)
    return str if str =~ /^[|[:alpha:]]+:\/\//  # Return absolute URLs, e.g. http://example.com
    return "http:#{str}" if str =~ /^\/\//      # //example.com -> http://example.com
    URI.join(uri.to_s, str).to_s                # Join relative path to base URL
  rescue URI::InvalidURIError => error
    logger.error "Invalid URL: #{str}"
    return nil
  end

  def http_get(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5
    http.open_timeout = 5
    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    resp = http.start() do |http|
      http.get(uri.request_uri)
    end
    logger.info "[#{resp.code}] #{uri}"
    if ["301", "302", "307"].include? resp.code
      uri = URI.parse resp["location"]
    elsif resp.code.to_i >= 400
      return
    end
    resp.body
  rescue StandardError => error
    logger.error error.to_s
  end

  def download_resource(url, path)
    return if File.exists? path
    if url =~ URI::regexp
      logger.info "Downloading #{url} to #{path}"
      FileUtils.mkdir_p File.dirname(path)
      data = http_get URI.parse(url)
      File.open(path, "wb") { |f| f.write(data) } if data
    end
  end

  def localize(url, dir)
    resource_url = url_for(url)
    return url unless resource_url

    dest = localize_url(url, dir)
    if search_resource? resource_url
      doc = RemoteDocument.new URI(resource_url)
      doc.exclude_resources = self.exclude_resources
      doc.search_resources = self.search_resources
      doc.mirror(dest)
    else
      delay
      download_resource(resource_url, dest)
    end
    relative_path(dir, dest)
  end

  def relative_path(base, path)
    Pathname.new(path).relative_path_from(Pathname.new(base)).to_s
  end

  def delay
    # Add a small delay between requests
    sleep(rand / 100)
  end

  def has_extension?(url)
    File.extname(url).length > 0
  end

  def excluded_resource?(url)
    exclude_resources.any? { |r| url =~ r }
  end

  def search_resource?(url)
    search_resources.any? { |r| url =~ r }
  end

  def replace_contents(pattern, replacement)
    @contents.gsub!(pattern, replacement)
  end

  def save_locally(path)
    dir = File.dirname path
    FileUtils.mkdir_p(dir) unless Dir.exists? dir

    # Download resources and localize URLs
    localized = Hash.new
    @resources.each { |url| localized[url] = localize(url, dir) }

    # Replace URLs in contents with localized versions
    localized.each { |key, value| replace_contents(key, value) }

    logger.info "Saving contents to #{path}"
    File.open(path, "w") { |f| f.write(@contents) }
  end

  def logger
    @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
  end
end
