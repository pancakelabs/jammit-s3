require 'rubygems'
require 'hmac'
require 'hmac-sha1'
require 'net/https'
require 'base64'
require 'mimemagic'
require 'digest/md5'

module Jammit
  class S3Uploader
    def initialize(options = {})
      @bucket = options[:bucket]
      unless @bucket
        @bucket_name = options[:bucket_name] || Jammit.configuration[:s3_bucket]
        @access_key_id = options[:access_key_id] || Jammit.configuration[:s3_access_key_id]
        @secret_access_key = options[:secret_access_key] || Jammit.configuration[:s3_secret_access_key]
        @bucket_location = options[:bucket_location] || Jammit.configuration[:s3_bucket_location]
        @cache_control = options[:cache_control] || Jammit.configuration[:s3_cache_control]
        @acl = options[:acl] || Jammit.configuration[:s3_permission]

        @bucket = find_or_create_bucket
      end
    end

    def upload
      log "Pushing assets to S3 bucket: #{@bucket.name}"
      s3_upload_files = Jammit.configuration[:s3_upload_files]

      # upload all the globs
      s3_upload_files.each do |file|
        send_to_s3(file)
      end
    end

    def send_to_s3(file)
      # check if the file already exists on s3
      obj = @bucket.objects.find_first(file["dest"]) rescue nil

      # if the object does not exist, or if the MD5 Hash / etag of the
      # file has changed, upload it
      if obj
        log "File not uploaded - already exists: #{file["dest"]}, are you sure you updated base_css_version and base_js_version?"
      else
        # save to s3
        new_object = @bucket.objects.build(file["dest"])
        new_object.cache_control = @cache_control if @cache_control
        new_object.content_encoding = 'gzip' if File.extname(file["src"]) == '.gz'
        new_object.content_type = MimeMagic.by_path(file["dest"].gsub(/\.gz$/, ''))
        new_object.content = open(file["src"])
        new_object.acl = @acl if @acl
        log "Uploading '#{file["src"]}' to '#{file["dest"]}'"
        new_object.save
      end
    end

    def find_or_create_bucket
      s3_service = S3::Service.new(:access_key_id => @access_key_id,
                                   :secret_access_key => @secret_access_key)

      # find or create the bucket
      begin
        s3_service.buckets.find(@bucket_name)
      rescue S3::Error::NoSuchBucket
        raise "Bucket not found '#{@bucket_name}', exiting."
      end
    end

    def log(msg)
      puts msg
    end

  end

end
