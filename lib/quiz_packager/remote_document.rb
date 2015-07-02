require "net/http"
require "uri"
require "fileutils"
require "logger"
require "pathname"

class RemoteDocument
  attr_reader :uri
  attr_reader :contents
  attr_reader :resources
  attr_accessor :exclude_resources

  def initialize(uri)
    @uri = uri
    @exclude_resources = []
  end

  def mirror(path)
    logger.info "Mirroring #{uri} to #{path}"
    load_contents
    find_resources
    save_locally path
  end

private

  def load_contents
    @contents = html_get uri
  end

  def find_resources
    @resources = (
      find_urls + 
      find_asset_paths +
      find_network_paths
    ).uniq.reject{|u|excluded_resource?(u)}
  end

  def find_urls
    # Only return URLs that have a file extension
    URI.extract(@contents, ["http", "https"]).select{ |url| File.extname(url).length > 0 }
  end

  def find_asset_paths
    # e.g. '/assets/example.jpg'
    @contents.scan(/(?<=["'])\/assets[^"'\s\\]+/).flatten
  end

  def find_network_paths
    # e.g. '//example.com/script.js'
    @contents.scan(/(?<=["'])\/\/[^"'\s\\]+/).flatten
  end

  def localize_url(url, dir)
    path = url.gsub(/^[|[:alpha]]+:\/\//, "")
    path.gsub!(/^[.\/]+/, "")
    path.gsub!(/\?.*/, "")  # Remove query string
    File.join(dir, path)
  end

  def url_for(str)
    return str if str =~ /^[|[:alpha:]]+:\/\//  # Return absolute URLs, e.g. http://example.com
    return "http:#{str}" if str =~ /^\/\//      # //example.com -> http://example.com
    URI.join(uri.to_s, str).to_s                # Join relative path to base URL
  end

  def html_get(uri)
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
    return
  end

  def download_resource(url, path)
    logger.info "Downloading #{url} to #{path}"
    FileUtils.mkdir_p File.dirname(path)
    uri = URI.parse(url)
    if uri
      data = html_get uri
      File.open(path, "wb") { |f| f.write(data) } if data
    end
  end

  def localize(url, dir)
    delay
    resource_url = url_for(url)
    dest = localize_url(url, dir)
    download_resource(resource_url, dest)
    relative_path(dir, dest)
  end

  def relative_path(base, path)
    Pathname.new(path).relative_path_from(Pathname.new(base)).to_s
  end

  def delay
    sleep(rand / 100)
  end

  def excluded_resource?(url)
    exclude_resources.any? { |u| url[u] }
  end

  def replace_contents(pattern, replacement)
    @contents.gsub(pattern, replacement)
  end

  def save_locally(path)
    dir = File.dirname path
    Dir.mkdir(dir) unless Dir.exists? dir

    # download resources
    localized = Hash.new
    @resources.each { |url| localized[url] = localize(url, dir) }

    # Replace resource URLs with local versions
    localized.each { |key, value| replace_contents(key, value) }

    logger.info "Saving contents to #{path}"
    File.open(path, "w") { |f| f.write(@contents) }
  end

  def logger
    @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
  end
end
