require "net/http"
require "uri"
require "nokogiri"
require "fileutils"
require "logger"

class RemoteDocument
  attr_reader :uri
  attr_reader :contents
  attr_reader :css_tags, :js_tags, :img_tags, :link_tags

  def initialize(uri)
    @uri = uri
  end

  def mirror(path)
    source = html_get uri
    @contents = Nokogiri::HTML source
    process_contents
    save_locally path
  end

  def process_contents
    @css_tags = @contents.xpath( "//link[@rel='stylesheet']" )
    @js_tags = @contents.xpath("//script[@src]")
    @img_tags = @contents.xpath( "//img[@src]" )
    find_links
  end

  def find_links
    @links = {}
    @contents.xpath("//a[@href]").each do |tag| 
      @links[tag[:href]] = (tag[:title] || "") if (! @links.include? tag[:href])
    end
  end

  def localize_url(url, dir)
    path = url.gsub(/^[|[:alpha]]+:\/\//, "")
    path.gsub!(/^[.\/]+/, "")
    path.gsub!(/[^-_.\/[:alnum:]]/, "_")
    File.join(dir, path)
  end

  def url_for(str)
    return str if str =~ /^[|[:alpha:]]+:\/\//
    URI.join(uri.to_s, str).to_s
  end

  def html_get(url)
    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = 5
    http.open_timeout = 5
    resp = http.start() do |http|
      http.get(url.path)
    end
    logger.info "[#{resp.code}] #{url}"
    if ["301", "302", "307"].include? resp.code
      url = URI.parse resp["location"]
    elsif resp.code.to_i >= 400
      return
    end
    resp.body
  rescue StandardError
    return
  end

  def download_resource(url, path)
    logger.info "Downloading #{url} to #{path}"
    FileUtils.mkdir_p File.dirname(path)
    the_uri = URI.parse(url)
    if the_uri
      data = html_get the_uri
      File.open(path, "wb") { |f| f.write(data) } if data
    end
  end

  def localize(tag, sym, dir)
    delay
    url = tag[sym]
    resource_url = url_for(url)
    dest = localize_url(url, dir)
    download_resource(resource_url, dest)
    tag[sym.to_s] = dest.partition(File.dirname(dir) + File::SEPARATOR).last
  end

  def delay
    sleep(rand / 100)
  end

  def save_locally(path)
    dir = File.dirname path
    Dir.mkdir(dir) unless Dir.exists? dir
   
    # remove HTML BASE tag if it exists
    @contents.xpath("//base").each { |t| t.remove }

    # save resources
    @img_tags.each { |tag| localize(tag, :src, File.join(dir, "images")) }
    @js_tags.each { |tag| localize(tag, :src, File.join(dir, "js")) }
    @css_tags.each { |tag| localize(tag, :href, File.join(dir, "css")) }

    logger.info "Saving contents to #{path}"
    File.open(path, "w") { |f| f.write(@contents.to_html) }
  end

  def logger
    @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
  end
end
