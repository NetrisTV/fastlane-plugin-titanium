module Fastlane
  module Actions
    module SharedValues
      TI_BUILD_IOS_CUSTOM_VALUE = :TI_BUILD_IOS_CUSTOM_VALUE
    end

    class TiBuildIosAction < Action

      @output
      @ipa
      @ti_profile
      @ti_build_old = false
      @ti_build_cmd
      @build_type
      
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        # UI.message "Parameter API Token: #{params[:api_token]}"
        @uuid = Actions.lane_context[SharedValues::SIGH_UUID]
        @output = params[:output_directory]

        @ti_build_old = params[:old]
        @ti_profile = params[:profile]

        @ti_target = "dist-adhoc"
        
        @build_type = params[:type]

        if @build_type == "appstore"
          @ti_target = "dist-appstore"
        end
        
        sh "env"

        if @ti_build_old
          @ti_build_cmd = "./scripts/build.js build"
          if @ti_profile
            @ti_build_cmd += " -p #{@ti_profile}"
          end

          @ti_build_cmd += " --"
        else
          @ti_build_cmd = "ti build"
          if @ti_profile
            @ti_build_cmd += " --build-profile #{@ti_profile}"
          end

        end

        
        @ti_build_cmd += " -p ios -T #{@ti_target} -R \"#{params[:team_name]}\" -O \"#{@output}\" -P #{@uuid} --log-level trace -F universal"

        # UI.message "!!!cmd #{@ti_build_cmd}"
        
        sh @ti_build_cmd
        
        @ipa = Dir["#{@output}/*.ipa"].first

        if @ipa.include?(".ipa")
          Actions.lane_context[SharedValues::IPA_OUTPUT_PATH] = @ipa
          ENV[SharedValues::IPA_OUTPUT_PATH.to_s] = @ipa # for deliver
        end
        
        # Actions.lane_context[SharedValues::TI_BUILD_IOS_CUSTOM_VALUE] = "my_val"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Titanium build action"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "You can use this action to do cool things..."
      end

      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :type,
                                       env_name: "TI_BUILD_TYPE", # The name of the environment variable
                                       description: "enterprise, adhoc or appstore", # a short description of this parameter
                                       default_value: "adhoc",
                                       verify_block: proc do |value|
                                         UI.message "!!!wtf #{value}"
                                         UI.user_error!("Invlid Titanium build type") unless (["adhoc", "enterprise", "appstore"].include?(value))
                                          # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :old,
                                       env_name: "TI_BUILD_OLD", # The name of the environment variable
                                       description: "Whether we should use ./scripts/build.js command", # a short description of this parameter
                                       is_string: false
                                      ),
          FastlaneCore::ConfigItem.new(key: :profile,
                                       env_name: "TI_PROFILE", # The name of the environment variable
                                       description: "Titanium build profile", # a short description of this parameter
                                      ),
          FastlaneCore::ConfigItem.new(key: :team_name,
                                       env_name: "TI_TEAM_NAME", # The name of the environment variable
                                       description: "Team name", # a short description of this parameter
                                       verify_block: proc do |value|
                                          UI.user_error!("No team name for TiBuildIosAction given, pass using `team_name`") unless (value and not value.empty?)
                                          # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :output_directory,
                                       env_name: "TI_OUTPUT_DIRECTORY", # The name of the environment variable
                                       description: "Output directory", # a short description of this parameter
                                       default_value: "build/out"
                                      ),
        #   FastlaneCore::ConfigItem.new(key: :development,
        #                                env_name: "FL_TI_BUILD_IOS_DEVELOPMENT",
        #                                description: "Create a development certificate instead of a distribution one",
        #                                is_string: false, # true: verifies the input is a string, false: every kind of value
        #                                default_value: false) # the default value if the user didn't provide one
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        [
          ['IPA_OUTPUT_PATH', @ipa]
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["Your GitHub/Twitter Name"]
      end

      def self.is_supported?(platform)
        # you can do things like
        # 
        #  true
        # 
        #  platform == :ios
        # 
        #  [:ios, :mac].include?(platform)
        # 

        platform == :ios
      end
    end
  end
end
