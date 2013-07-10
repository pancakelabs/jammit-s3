require 'jammit/command_line'
require 'jammit/s3_command_line'
require 'jammit/s3_uploader'

module Jammit
  def self.upload_to_s3!(options = {})
    S3Uploader.new(options).upload
  end

  # Generates the server-absolute URL to an asset package.
  def self.asset_url(package, extension, suffix=nil, mtime=nil)
    if Jammit.configuration[:use_cloudfront] && Jammit.configuration[:cloudfront_cname].present? && Jammit.configuration[:cloudfront_domain].present?
      asset_hostname = Jammit.configuration[:cloudfront_cname]
      asset_hostname_ssl = Jammit.configuration[:cloudfront_domain]
    elsif Jammit.configuration[:use_cloudfront] && Jammit.configuration[:cloudfront_domain].present?
      asset_hostname = asset_hostname_ssl = Jammit.configuration[:cloudfront_domain]            
    else
      asset_hostname = asset_hostname_ssl = "#{Jammit.configuration[:s3_bucket]}.s3.amazonaws.com"
    end
      
    protocol = (Jammit.configuration.has_key?(:ssl) && Jammit.configuration[:ssl]) ? "https://" : "http://"

    asset = Jammit.configuration[:s3_upload_files].find{|asset| asset["src"].gsub(/.*\//, '') == "#{package}.#{extension}"}
    asset_path = asset["dest"]

    timestamp = mtime ? "?#{mtime.to_i}" : ''
    if protocol == "https://"
      "#{protocol}#{asset_hostname_ssl}/#{asset_path}#{timestamp}"
    else 
      "#{protocol}#{asset_hostname}/#{asset_path}#{timestamp}"
    end
  end
end