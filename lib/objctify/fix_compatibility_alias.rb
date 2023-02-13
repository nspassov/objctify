module Objctify

    ObjCCompAlias = Struct.new(:alias, :original)

    def self.fix_compatibility_alias(sources, headers, framework_headers)
        
        $logger.info("Fixing aliases in smart-import and declarations")

        aliases = Array([])

        framework_headers.each do |header|
            pairs = File.read(header).scan(/@compatibility_alias\s(\w+)\s(\w+);/m).map { |item| ObjCCompAlias.new(item[0], item[1]) }
            unless pairs.nil?
                pairs.each do |pair|
                    aliases.append(pair)
                end
            end
        end

        $logger.debug("Found aliases #{aliases}")

        aliases.each do |pair|
            Objctify::replace_alias(sources, pair.alias, pair.original)
            Objctify::replace_alias(headers, pair.alias, pair.original)
        end
    end
    
    def self.replace_alias(files, c_alias, replacement)
        files
            .map(&:file_ref)
            .select { |file_ref|   
                $logger.debug("Looking at #{file_ref.display_name} at #{file_ref.full_path}")
                file_body = File.read(file_ref.full_path)
                file_body.include?(c_alias)
            }
            .each do |file_ref|
                $logger.debug("Replacing aliases in #{file_ref.display_name}")
                
                file_body = File.read(file_ref.full_path)
                
                file_body = file_body.gsub(/#{c_alias}/, "#{replacement}")

                File.open(file_ref.full_path, 'w') do |file|
                    file.puts file_body
                end
            end
    end

end