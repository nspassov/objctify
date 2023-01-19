module Objctify

  def self.cleanAll(project_name)
    call = "rm -rf #{project_name}; rm -rf #{project_name}/DXCCore.xcodeproj; rm -rf j2objc_dist; rm -rf JRE.xcframework"
    puts call
    system(call)
  end

end
