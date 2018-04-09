require 'fastlane/action'
require_relative '../helper/titanium_helper'

module Fastlane
  module Actions
    module SharedValues
      TITANIUM_IOS_RELEASE_BUILD_PATH = :TITANIUM_IOS_RELEASE_BUILD_PATH
      TITANIUM_ANDROID_RELEASE_BUILD_PATH = :TITANIUM_ANDROID_RELEASE_BUILD_PATH
    end

    class TitaniumAction < Action
      
      # Mapping action parameters to cli args
      ANDROID_ARGS_MAP = {
        keystore: 'keystore',
        keystore_password: 'store-password',
        keystore_alias: 'alias',
        log_level: 'log-level',
        target: "target",
      }

      IOS_ARGS_MAP = {
        target: 'target',
        team_name: nil,
        pp_uuid: 'pp-uuid',
        log_level: 'log-level',
      }

      def self.get_platform_args(params, args_map)
        platform_args = []
        args_map.each do |action_key, cli_param|
          param_value = params[action_key]
          param_key = cli_param
          
          if(action_key == :team_name)
            param_key = params[:target] == "device" ? "developer-name" : "distribution-name"
          end
          
          unless param_value.to_s.empty?
            platform_args << "--#{param_key}=#{Shellwords.escape(param_value)}"
          end
        end

        return platform_args
      end

      def self.get_android_args(params)
        if params[:target].empty? || params[:target] == "playstore"
          params[:target] = "dist-playstore"
        end
        return self.get_platform_args(params, ANDROID_ARGS_MAP)
      end

      def self.get_ios_args(params)
        app_identifier = CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)

        if params[:pp_uuid].empty?
          params[:pp_uuid] = ENV['SIGH_UUID'] || ENV["sigh_#{app_identifier}_#{params[:type].sub("-","")}"]
        end

        if params[:target] == 'adhoc' || params[:target] == "enterprise"
          params[:target] = 'dist-adhoc'
        end
 
       if params[:target] == 'appstore'
          params[:target] = 'dist-appstore'
        end

        return self.get_platform_args(params, IOS_ARGS_MAP)
      end

      def self.build(params)
        args = []
        args << "--device-id #{params[:device_id]}" if params[:device_id]

        if params[:target] != "device"
          args << "--output-dir ./build/out"
        end
        
        if params[:platform].to_s == 'android'
          args << "-p android"
          if !params[:target] || params[:target].to_s.empty?
            params[:target] = "dist-playstore"
          end
          args += self.get_android_args(params)
        else
          args << "-p ios"
          if !params[:target] || params[:target].to_s.empty?
            params[:target] = "dist-adhoc"
          end
          args += self.get_ios_args(params)
        end

        build_cmd = "ti build"
        if params[:obsolete]
          build_cmd = "scripts/build.js"
          if !params[:build_profile].to_s.empty?
            build_cmd += " -p #{params[:build_profile]}"
          end
          build_cmd += " -- build "
        else
          if !params[:build_profile].to_s.empty?
            build_cmd += " --build-profile #{params[:build_profile]}"
          end
        end

        output = nil

        sh "#{build_cmd} #{args.join(' ')}"
        
        if params[:platform].to_s == 'android'
          output = Dir["./build/out/*.apk"].first
          ENV['TITANIUM_ANDROID_RELEASE_BUILD_PATH'] = output

          Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH] = output
        else
          output = Dir["./build/out/*.ipa"].first
          ENV['TITANIUM_IOS_RELEASE_BUILD_PATH'] = output

          Actions.lane_context[SharedValues::IPA_OUTPUT_PATH] = output
          ENV[SharedValues::IPA_OUTPUT_PATH.to_s] = output # for deliver

          sh "find build -name '*.dSYM' -exec zip -r '{}'.zip '{}' \\;"
          dsym = Dir["build/iphone/build/Products/Release-iphoneos/*.dSYM.zip"].first

          unless dsym.nil?
            ENV['TITANIUM_IOS_RELEASE_DSYM_PATH'] = output
            ENV["FL_HOCKEY_DSYM"] = dsym
          end
          
        end

        return output
      end

      def self.run(params)
        return self.build(params)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Build your Titanium app"
      end

      def self.details
        "Fastlane plugin for Axway Titanium"
      end

      def self.return_value
        "The absolute path to the generated ipa or apk file"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :platform,
            env_name: "TITANIUM_PLATFORM",
            description: "Platform to build on. Should be either android or ios",
            is_string: true,
            default_value: lane_context[SharedValues::PLATFORM_NAME].to_s,
            verify_block: proc do |value|
              UI.user_error!("Platform should be either android or ios") unless ['android', 'ios'].include? value
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :target,
            env_name: "TITANIUM_TARGET",
            description: "Build target. One of device, playstore, dist-adhoc, enterprise, appstore",
            is_string: true,
            optional: true,
            default_value: nil,
            verify_block: proc do |value|
              UI.user_error!("Invlid Titanium target") unless (["device", "dist-playstore", "playstore", "dist-adhoc", "adhoc", "enterprise", "dist-appstore", "appstore"].include?(value))
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :device_id,
            env_name: "TITANIUM_DEVICE_ID",
            description: "Build for given device",
            is_string: true,
            optional: true,
            default_value: nil,
          ),
          FastlaneCore::ConfigItem.new(
            key: :team_name,
            env_name: "TITANIUM_IOS_TEAM_NAME",
            description: "The development/distribution team to use for code signing",
            is_string: true,
            default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_name)
          ),
          FastlaneCore::ConfigItem.new(
            key: :pp_uuid,
            env_name: "TITANIUM_IOS_PROVISIONING_PROFILE",
            description: "GUID of the provisioning profile to be used for signing",
            is_string: true,
            default_value: ''
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore,
            env_name: "TITANIUM_ANDROID_KEYSTORE",
            description: "Path to the Keystore for Android",
            is_string: true,
            default_value: ''
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_password,
            env_name: "TITANIUM_ANDROID_KEYSTORE_PASSWORD",
            description: "Android Keystore password",
            is_string: true,
            default_value: ''
          ),
          FastlaneCore::ConfigItem.new(
            key: :keystore_alias,
            env_name: "TITANIUM_ANDROID_KEYSTORE_ALIAS",
            description: "Android Keystore alias",
            is_string: true,
            default_value: ''
          ),
          FastlaneCore::ConfigItem.new(
            key: :log_level,
            env_name: "TITANIUM_LOG_LEVEL",
            description: "Titanium log level",
            default_value: "trace",
            is_string: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_profile,
            env_name: "TITANIUM_BUILD_PROFILE",
            description: "Titanium build-profile when using ti.multiconfiguration plugin or ./scripts/build.js wrapper",
            default_value: '',
            is_string: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :obsolete,
            env_name: "TITANIUM_BUILD_OBSOLETE",
            description: "Whether to use ./scripts/build.js to build app",
            default_value: false,
            is_string: false
          )
        ]
      end

      def self.output
        [
          ['TITANIUM_ANDROID_RELEASE_BUILD_PATH', 'Path to the signed release APK if it was generated'],
          ['TITANIUM_IOS_RELEASE_BUILD_PATH', 'Path to the signed release IPA if it was generated']
        ]
      end

      def self.authors
        ['prop']
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        
        [:ios, :mac, :android].include?(platform)
      end

      def self.example_code
        [
          "titanium(
            platform: 'ios',
            target: 'adhoc'
          )",
          "titanium(
            platform: 'android',
            keystore: './staging.keystore',
            keystore_alias: 'alias_name',
            keystore_password: 'store_password'
          )"
        ]
      end

      def self.category
        :building
      end
    end
  end
end
