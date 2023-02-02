#
# Copyright Devexperts (2019)
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

require 'xcodeproj'

module Objctify

  class ProjectConfigurator

    def self.add_framework(path, project, target)
      path = File.expand_path(path)
      unless (ref = project.frameworks_group.find_file_by_path(path))
        ref = project.frameworks_group.new_file(path, :absolute)
      end
      target.frameworks_build_phase.add_file_reference(ref, true)
    end

    def self.add_headers(path, config)
      path = File.expand_path(path)
      config.build_settings['HEADER_SEARCH_PATHS'].append("#{path}/include")
    end

  end

  def self.generate_project(framework_name, useArc, external_frameworks)
    project = Xcodeproj::Project.new("#{framework_name}.xcodeproj")
    target = project.new_target(:framework, framework_name, :ios)

    source_build_phase = target.source_build_phase
    headers_build_phase = target.headers_build_phase

    #add files
    Pathname(framework_name).find do |path|
      dir, base = path.split
      if path.directory?

        if path.to_s == framework_name
          project.new_group base.to_s, base
        else
          group_to_append_to = project[dir.to_s]
          group_to_append_to.new_group base.to_s, base
        end

      elsif path.file?

        group = project[dir.to_s]
        new_ref = group.new_reference base

        if new_ref.last_known_file_type == 'sourcecode.c.h'
          build_file = headers_build_phase.add_file_reference new_ref
          build_file.settings = { ATTRIBUTES: ['', 'Public'] }
        elsif new_ref.last_known_file_type == 'sourcecode.c.objc'
          source_build_phase.add_file_reference new_ref
        end

      end
    end

    header_file_path = Pathname("#{framework_name}/#{framework_name}.h")

    File.open(header_file_path, 'w') do |header_file|
      header_template = "//
//  #{framework_name}.h
//  #{framework_name}
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

//! Project version number for #{framework_name}.
FOUNDATION_EXPORT double #{framework_name}VersionNumber;

//! Project version string for #{framework_name}.
FOUNDATION_EXPORT const unsigned char #{framework_name}VersionString[];

"
      header_file.write(header_template)
      header_file.write(headers_build_phase.files_references
        .map(&:path)
        .map { |header_file_name| "#include <#{framework_name}/" + header_file_name + '>' } * "\n"
      )

      unless external_frameworks.nil?
        header_file.write("\n")
        header_file.write(external_frameworks
          .map { |framework_path| File.basename(framework_path) }
          .map { |framework| "#import <#{framework}/#{framework}.h>\n" }
        )
      end
    end

    dir, base = header_file_path.split

    header_file_ref = project[dir.to_s].new_reference base
    header_build_file = headers_build_phase.add_file_reference header_file_ref
    header_build_file.settings = { ATTRIBUTES: ['', 'Public'] }

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
        config.build_settings['HEADER_SEARCH_PATHS'] = Array(["$(J2OBJC_HOME)/include"])
        unless external_frameworks.nil?
          external_frameworks.each do |framework|
            ProjectConfigurator::add_headers(framework, config)
          end
        end

        config.build_settings['MACH_O_TYPE'] = "staticlib"
        config.build_settings['GENERATE_INFOPLIST_FILE'] = true

        # ObjectiveC specific flags
        config.build_settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = true
        config.build_settings['CLANG_ENABLE_MODULES'] = true
        config.build_settings['CLANG_ENABLE_OBJC_ARC'] = useArc
        config.build_settings['CLANG_ENABLE_OBJC_WEAK'] = true
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = true

        if useArc
          config.build_settings['OTHER_LDFLAGS'] = Array(["-ObjC", "-fobjc-arc-exceptions", "-lz", "-licucore"])
          config.build_settings['OTHER_CFLAGS'] = Array(["-fobjc-arc"])
        else
          config.build_settings['OTHER_LDFLAGS'] = Array(["-ObjC", "-lz", "-licucore"])
        end

        # Workaround
        config.build_settings['SUPPORTS_MACCATALYST'] = false
      end
    end

    project.save
  end

end
