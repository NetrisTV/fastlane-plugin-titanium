# coding: utf-8
require 'fastlane_core/ui/ui'
require 'rexml/document'
include REXML

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class TitaniumHelper
      # class methods that you define here become available in your action
      # as `Helper::TitaniumHelper.your_method`
      #
      # def self.show_message
      #   UI.message("Hello from the titanium plugin helper!")
      # end

      def self.get_ti_sdk_version
        tiapp = File.new("./tiapp.xml")
        xmldoc = Document.new(tiapp)
        return XPath.first(xmldoc, "//sdk-version").text
      end
    end
  end
end
