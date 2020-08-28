require 'fastlane/action'
require_relative '../helper/simple_loco_helper'

module Fastlane
  module Actions
    class SimpleLocoAction < Action
      def self.run(params)
        config = Helper::Config.read_conf(params[:conf_file_path])

        UI.message('Exporting files')

        config.export_locales

        UI.success('Finished exporting files')
      end

      def self.description
        "A simple implementation for exporting translations from Loco."
      end

      def self.authors
        ["Yves Delcoigne"]
      end

      def self.return_value
      end

      def self.details
        "A wrapper implementation around the Localize export single-file API. See https://localise.biz/api/docs/export/exportlocale for all options. Common mobile platforms (Android, iOS, Xamarin, Flutter) have some extra logic to create the correct paths, and a custom implementation is provided for other platforms."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :conf_file_path,
                                       env_name: 'LOCO_CONF_FILE_PATH',
                                       description: 'The config file path',
                                       optional: true,
                                       type: String,
                                       default_value: 'fastlane/Loco.platform.json')
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
