require 'fastlane_core/ui/ui'
require 'fileutils'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    PLATFORM_IOS = 'ios'
    PLATFORM_ANDROID = 'android'
    PLATFORM_FLUTTER = 'flutter'
    PLATFORM_XAMARIN = 'xamarin'
    PLATFORM_CUSTOM = 'custom'

    class Config
      def initialize(platform:,
                     directory:,
                     locales:,
                     key:,
                     format: "",
                     filter: [],
                     index: "",
                     source: "",
                     namespace: "",
                     fallback: "",
                     order: "",
                     status: "",
                     printf: "",
                     charset: "",
                     breaks: "",
                     no_comments: "",
                     no_folding: "",
                     custom_extension: "",
                     custom_file_name: "")

        # Check for required fields
        missing_fields = []
        if platform.to_s.empty?
          missing_fields.push 'platform'
        end
        if directory.to_s.empty?
          missing_fields.push 'directory'
        end
        if key.to_s.empty?
          missing_fields.push 'key'
        end
        if locales.to_s.empty?
          missing_fields.push 'locales'
        end

        if !missing_fields.empty?
          raise "Not all required fields are filled: #{missing_fields.join(", ")}"
        end

        @platform = platform
        @directory = directory
        @locales = locales
        @key = key
        @format = format
        @filter = filter
        @index = index
        @source = source
        @namespace = namespace
        @fallback = fallback
        @order = order
        @status = status
        @printf = printf
        @charset = charset
        @breaks = breaks
        @no_comments = no_comments
        @no_folding = no_folding
  
        if platform == PLATFORM_ANDROID
          @adapter = AndroidAdapter.new
        elsif platform == PLATFORM_IOS
          @adapter = CocoaAdapter.new(
            format: format)
        elsif platform == PLATFORM_FLUTTER
          @adapter = FlutterAdapter.new
        elsif platform == PLATFORM_XAMARIN
          @adapter = XamarinAdapter.new
        elsif platform == PLATFORM_CUSTOM
          @adapter = CustomAdapter.new(
            custom_extension: custom_extension,
            custom_file_name: custom_file_name)
        else
          raise "Unsupported platform '#{platform}'"
        end
      end
  
      attr_reader :platform
      attr_reader :directory
      attr_reader :locales
      attr_reader :key
      attr_reader :format
      attr_reader :filter
      attr_reader :index
      attr_reader :source
      attr_reader :namespace
      attr_reader :fallback
      attr_reader :order
      attr_reader :status
      attr_reader :printf
      attr_reader :charset
      attr_reader :breaks
      attr_reader :no_comments
      attr_reader :no_folding

      def export_locales

        FileUtils.mkdir_p @directory unless File.directory? @directory

        @locales.each_with_index do |locale, index|

          @adapter.allowed_extensions.each do |extension|

            # Download
  
            result = export locale, extension
  
            if result.nil?
              raise "Could not export locale #{locale} with extension #{extension}"
            end
  
            # Write
  
            result_directory = locale_directory locale, index.zero?
            FileUtils.mkdir_p result_directory unless File.directory? result_directory

            @adapter.write_locale(result_directory,
                                  result,
                                  locale,
                                  extension,
                                  index.zero?)

          end
        end  
      end

      # Exports the locale for the corresponding extension
      #
      # @param [String] the locale
      # @param [String] the extension, must include the `.`
      def export(locale, extension)

        optional_query_params = {}
        if !@format.to_s.empty?
          optional_query_params["format"] = @format 
        end
        if @filter != nil && !filter.empty?
          optional_query_params["filter"] = @filter.join(',') 
        end
        if !@index.to_s.empty?
          optional_query_params["index"] = @index 
        end
        if !@source.to_s.empty?
          optional_query_params["source"] = @source 
        end
        if !@namespace.to_s.empty?
          optional_query_params["namespace"] = @namespace 
        end
        if !@fallback.to_s.empty?
          optional_query_params["fallback"] = @fallback 
        end
        if !@order.to_s.empty?
          optional_query_params["order"] = @order 
        end
        if !@status.to_s.empty?
          optional_query_params["status"] = @status 
        end
        if !@printf.to_s.empty?
          optional_query_params["printf"] = @printf 
        end
        if !@charset.to_s.empty?
          optional_query_params["charset"] = @charset 
        end
        if !@breaks.to_s.empty?
          optional_query_params["breaks"] = @breaks 
        end
        if !@no_comments.to_s.empty?
          optional_query_params["no-comments"] = @no_comments 
        end
        if !@no_folding.to_s.empty?
          optional_query_params["no-folding"] = @no_folding 
        end

        uri = URI::HTTPS.build(scheme: 'https',
                               host: 'localise.biz',
                               path: "/api/export/locale/#{locale}#{extension}",
                               query: URI.encode_www_form(optional_query_params)
                              )

        res = Net::HTTP.start(uri.host, uri.port,
          :use_ssl => uri.scheme == 'https') do |http|
            req = Net::HTTP::Get.new(uri)
            req['Authorization'] = "Loco #{@key}"
            http.request req
        end
  
        if res.code == '200'
          body = res.body
  
          # Extracting charset because Net does not do it
          content_type = res['Content-Type']
          charset = /charset=([^ ;]*)/.match content_type
          unless charset.nil?
            body = body.force_encoding(charset.captures[0])
                       .encode('utf-8')
          end
  
          return body
        end
  
        warn 'URL failed: ' + uri.to_s
        nil
      end
  
      def locale_directory(locale, is_default)  
        return File.join(@directory,
                  @adapter.directory(locale, is_default))
      end
  
      # Static method used to read a config file
      def self.read_conf(path)
        accepted_formats = [".json", ".yaml", ".yml"]
        extension = File.extname(path)

        if !accepted_formats.include?(extension)
          raise "Unsupported config file format #{extension}, only JSON and YAML files are supported."
        end

        data = YAML.safe_load(File.read(path))
        config = data.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = v; }
        return Config.new(**config)
      end
    end

    class BaseAdapter
      # ====================================
      # Methods to override
  
      # All the extensions allowed for that adapter
      #
      # This method is also used to determine what to load from the server
      #
      # Must be written with the '.' like '.xml'
      #
      # @return [Array] an array of all the allowed extensions
      def allowed_extensions
        return []
      end
  
      # Returns res directory for the mapped locale
      #
      # Base implementation does nothing
      #
      # @param [String] the mapped locale name
      # @param [true] whether the locale is the default one
      def directory(locale, is_default)
        return ''
      end
  
      # Returns the default name
      def default_file_name
        return ''
      end
  
      # Writes the locale to a directory
      def write_locale(directory,
                        result, 
                        locale, 
                        extension,
                        is_default)
        path = File.join(directory, default_file_name + extension)
        File.write path, result
      end
    end

    class AndroidAdapter < BaseAdapter  
      def allowed_extensions
        return ['.xml']
      end
  
      def directory(locale, is_default)
        return is_default ? 'values' : "values-#{locale}"
      end
  
      def default_file_name
        return 'strings'
      end
    end

    class CocoaAdapter < BaseAdapter
      def initialize(format:)
        @format = format
      end

      attr_reader :format

      def allowed_extensions
        if @format == 'plist'
          return ['.strings']
        else
          return ['.strings', '.stringsdict']
        end
      end
  
      def directory(locale, is_default)
        return "#{locale}.lproj"
      end
  
      def default_file_name
        if @format == 'plist'
          return 'InfoPlist'
        else
          return 'Localizable'
        end
      end
    end

    class FlutterAdapter < BaseAdapter
      def allowed_extensions
        return ['.arb']
      end

      def default_file_name
        return 'intl_messages_'
      end

      def write_locale(directory,
                        result, 
                        locale, 
                        extension,
                        is_default)
        path = File.join(directory, default_file_name + locale + extension)
        File.write path, result
      end
    end

    class XamarinAdapter < BaseAdapter
      def allowed_extensions
        return ['.resx']
      end
  
      def default_file_name
        return 'AppResources'
      end

      def write_locale(directory,
        result, 
        locale, 
        extension,
        is_default)

        path = nil
        if is_default
          path = File.join(directory, default_file_name + extension)
        else
          path = File.join(directory, default_file_name + ".#{locale}" + extension)
        end

        File.write path, result
      end
    end

    class CustomAdapter < BaseAdapter
      def initialize(custom_extension:,
                    custom_file_name:)
        @custom_extension = custom_extension
        @custom_file_name = custom_file_name
      end

      attr_reader :custom_extension
      attr_reader :custom_file_name
  
      def allowed_extensions
        return [@custom_extension]
      end
  
      def default_file_name
        return @custom_file_name
      end

      def write_locale(directory,
        result, 
        locale, 
        extension,
        is_default)

        path = nil

        used_extension = extension
        if !used_extension.start_with?('.')
          used_extension = ".#{used_extension}"
        end

        if default_file_name.nil? || default_file_name.empty?
          path = File.join(directory, locale + used_extension)
        elsif is_default
          path = File.join(directory, default_file_name + used_extension)
        else
          path = File.join(directory, default_file_name + ".#{locale}" + used_extension)
        end

        File.write path, result
      end
    end

  end
end