#
# Copyright Devexperts (2019)
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

require 'xcodeproj'

module Objctify

  def self.generate_project(framework_name, useArc, external_frameworks, objc_sources)
    project = Xcodeproj::Project.new("#{framework_name}.xcodeproj")
    target = project.new_target(:framework, framework_name, :ios)

    source_build_phase = target.source_build_phase
    headers_build_phase = target.headers_build_phase

    #add files
    ProjectConfigurator::add_files(framework_name, project, source_build_phase, headers_build_phase)
    unless objc_sources.nil?
      ProjectConfigurator::add_files(objc_sources, project, source_build_phase, headers_build_phase)
    end

    # add headers
    ProjectConfigurator::create_header(project, headers_build_phase, framework_name, external_frameworks)

    project.targets.each do |target|
      target.add_system_library_tbd(%w[z iconv])
      target.add_system_framework('UIKit')
      target.add_system_framework('Foundation')

      ProjectConfigurator::add_framework("JRE.xcframework", project, target)

      unless external_frameworks.nil?
        external_frameworks.each do |framework|
          ProjectConfigurator::add_framework(framework, project, target)
        end
      end

      target.build_configurations.each do |config|

        # Framework specific flags
        config.build_settings['J2OBJC_HOME'] = "j2objc_dist"
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] = "$(J2OBJC_HOME)/frameworks"
        config.build_settings['HEADER_SEARCH_PATHS'] = Array(["$(J2OBJC_HOME)/include", "$(J2OBJC_HOME)/frameworks/JRE.xcframework/Headers"])
        config.build_settings['SWIFT_INCLUDE_PATHS'] = "$(J2OBJC_HOME)/frameworks/JRE.xcframework/Headers"
        unless external_frameworks.nil?
          external_frameworks.each do |framework|
            ProjectConfigurator::add_headersPath(framework, config)
          end
        end

        config.build_settings['MACH_O_TYPE'] = "staticlib"
        config.build_settings['DEFINES_MODULE'] = true
        config.build_settings['GENERATE_INFOPLIST_FILE'] = true

        # ObjectiveC specific flags
        config.build_settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = true
        config.build_settings['CLANG_ENABLE_MODULES'] = true
        config.build_settings['CLANG_ENABLE_OBJC_ARC'] = useArc
        config.build_settings['CLANG_ENABLE_OBJC_WEAK'] = true
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = false
        config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = true

        if useArc
          config.build_settings['OTHER_LDFLAGS'] = Array(["-ObjC", "-fobjc-arc-exceptions", "-lz", "-licucore"])
          config.build_settings['OTHER_CFLAGS'] = Array(["-fobjc-arc", "-fembed-bitcode"])
        else
          config.build_settings['OTHER_LDFLAGS'] = Array(["-ObjC", "-lz", "-licucore"])
          config.build_settings['OTHER_CFLAGS'] = Array(["-fembed-bitcode"])
        end

        # Workaround
        config.build_settings['SUPPORTS_MACCATALYST'] = false
      end
    end

    project.save
    project
  end

end
