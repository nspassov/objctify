module Objctify
    class JreHeaderComposer

        def self.compose(headers_folder, framework_name)
            umbrella_header_path = "#{framework_name}_JRE_Umbrella.h"
            jre_headers = Dir["#{headers_folder}/**/*.h"].map { |header_path| header_path.delete_prefix("#{headers_folder}/") }

            File.open(umbrella_header_path, 'w') do |header_file|
                header_template = Templates::jre_header(framework_name)
                header_file.write(header_template)
        
                header_file.write(jre_headers
                  .map { |header_file_name| "#include \"" + header_file_name + '\"' } * "\n"
                )
        
            end
            umbrella_header_path
        end

    end

end