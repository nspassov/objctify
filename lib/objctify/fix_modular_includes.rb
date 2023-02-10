
module Objctify

    def self.fix_modular_includes(sources, headers, framework_name, framework_header)
        
        $logger.info("Fixing include-blocks of headers from framework #{framework_name}")

        # extract all headers from umbrella header of framework
        if framework_name == ""
            framework_headers = File.read(framework_header).scan(/\<([\w?+\/]+.h)\>/m).map { |item| item[0] }
        else
            framework_headers = File.read(framework_header).scan(/\<#{framework_name}\/([\w?+\/]+.h)\>/m).map { |item| item[0] }
        end
        # iterate through all files of target
        Objctify::replace_includes(sources, framework_name, framework_headers)
        Objctify::replace_includes(headers, framework_name, framework_headers)
    end
    
    def self.replace_includes(files, framework_name, headers)
        files
            .map(&:file_ref)
            .select { |file_ref|   
                $logger.debug("Looking at #{file_ref.display_name} at #{file_ref.full_path}")
                file_body = File.read(file_ref.full_path)
                headers.any? { |header| file_body.include?(header) }
            }
            .each do |file_ref|
                $logger.debug("Replacing includes in #{file_ref.display_name}")
                
                file_body = File.read(file_ref.full_path)

                # replace #include "Header.h" with #include <Module/Header.h>
                headers.each do |header|
                    if framework_name == ""
                        file_body = file_body.gsub(/<#{header}>/, "\"#{header}\"")
                    else
                        file_body = file_body.gsub(/\"#{header}\"/, "<#{framework_name}/#{header}>")
                    end
                end

                File.open(file_ref.full_path, 'w') do |file|
                    file.puts file_body
                end
            end
    end

end