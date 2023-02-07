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

    def self.add_headersPath(path, config)
      path = File.expand_path(path)
      config.build_settings['HEADER_SEARCH_PATHS'].append("#{path}/include")
    end

    def self.add_files(folder, project, source_build_phase, headers_build_phase)
      Pathname(folder).find do |path|
        dir, base = path.split
        if path.directory?
          if path.to_s == folder
            project.new_group base.to_s, base
          elsif group_to_append_to = project[dir.to_s]
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
    end

    def self.create_header(project, headers_build_phase, framework_name, external_frameworks)
      header_file_path = Pathname("#{framework_name}/#{framework_name}.h")

      File.open(header_file_path, 'w') do |header_file|
        header_template = Templates::header(framework_name)
        header_file.write(header_template)

        unless external_frameworks.nil?
          header_file.write("\n")
          header_file.write(external_frameworks
            .map { |framework_path| File.basename(framework_path, ".xcframework") }
            .map { |framework| "#import <#{framework}/#{framework}.h>" } * "\n"
          )
        end

        header_file.write("\n")

        header_file.write(headers_build_phase.files_references
          .map(&:path)
          .map { |header_file_name| "#include <#{framework_name}/" + header_file_name + '>' } * "\n"
        )

      end

      dir, base = header_file_path.split

      header_file_ref = project[dir.to_s].new_reference base
      header_build_file = headers_build_phase.add_file_reference header_file_ref
      header_build_file.settings = { ATTRIBUTES: ['', 'Public'] }
    end

  end

end
