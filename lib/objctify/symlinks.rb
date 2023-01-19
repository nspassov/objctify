
module Objctify

  def self.refreshSymlinks(j2objc_home)
    call = "ln -s #{j2objc_home} j2objc_dist; ln -s j2objc_dist/frameworks/JRE.xcframework JRE.xcframework"
    puts call
    system(call)
  end

end
