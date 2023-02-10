#
# Copyright Devexperts (2019)
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

module Objctify
  class Command
    class This < Command
      self.summary = 'Creates xcodeproj from java sources with j2objc'
      self.description = 'Creates xcodeproj from java source with j2objc using configuration from Objctifile'

      def run
        file_path = "#{Dir.pwd}/Objctifile"

        unless File.exist?(file_path)
          raise Objctify::Informative, "Couldn't find Objctifile"
        end

        file_contents = File.read(file_path)

        project = Context.new
        project.instance_eval(file_contents, file_path)

        if project.project_name_param.nil?
          raise Objctify::Informative, "Project name is not provided in Objctifile"
        end
        if project.java_sources_param.nil?
          raise Objctify::Informative, "Path to Java sources is not provided in Objctifile"
        end

        raise Objctify::Informative, "Provided Java sources directory does not exist: #{project.java_sources_param}" unless
            Dir.exist?(project.java_sources_param)

        framework_name = project.project_name_param
        java_sources = File.expand_path(project.java_sources_param)
        j2objc_home = File.expand_path(project.j2objc_config.distr_dir)
        dependencies = project.project_dependencies_param
        external_frameworks = project.project_frameworks_param
        objc_sources = project.objc_sources_param

        Objctify::cleanAll(framework_name)

        Objctify::refreshSymlinks(j2objc_home)

        unless project.j2objc_config.prefixes_file_path.nil?
          unless File.exist?(project.j2objc_config.prefixes_file_path)
            raise Objctify::Informative, "Specified prefixes file does not exist: #{project.j2objc_config.prefixes_file_path}"
          end

          prefix_file_path = File.expand_path(project.j2objc_config.prefixes_file_path)
        end

        Objctify::translate_files(java_sources, prefix_file_path, framework_name, dependencies, project.j2objc_config.extra_cli_args)
        $logger.info('Cleaning')
        Objctify::fix_imports(framework_name, prefix_file_path)
        $logger.info('Plumbing')
        jre_header_path = JreHeaderComposer.compose("j2objc_dist/include", framework_name)
        useArc = project.j2objc_config.extra_cli_args.include? "-use-arc"
        project = Objctify::generate_project(framework_name, useArc, external_frameworks, objc_sources)
        $logger.info('Patching')
        sources = project.targets.first().source_build_phase.files
        headers = project.targets.first().headers_build_phase.files
        framework_header = headers.find { |file| file.display_name == "#{framework_name}.h" }.file_ref.full_path
        # fix modular includes for main framework
        Objctify::fix_modular_includes(sources, headers, framework_name, framework_header)
        # fix modular includes for JRE frameworks
        Objctify::fix_modular_includes(sources, headers, "", jre_header_path)
        # fix modular includes for external frameworks
        unless external_frameworks.nil?
          external_frameworks.each do |framework_path|
            framework_name = File.basename(framework_path, ".xcframework")
            framework_header = "#{framework_path}/include/#{framework_name}.h"
            Objctify::fix_modular_includes(sources, headers, framework_name, framework_header)
          end
        end
        $logger.info('Done')
      end
    end
  end
end
