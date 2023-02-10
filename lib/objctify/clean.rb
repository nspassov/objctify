module Objctify

  def self.cleanAll(project_name)
    call = "rm -rf #{project_name}; rm -rf #{project_name}/#{project_name}.xcodeproj; rm -rf j2objc_dist; rm -rf JRE.xcframework"
    $logger.debug(call)
    system(call)
  end

end
