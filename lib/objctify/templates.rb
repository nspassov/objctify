module Objctify 

    class Templates 

        def self.header(name)
            "//
//  #{name}.h
//  #{name}
//
//
          
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
          
//! Project version number for #{name}.
FOUNDATION_EXPORT double #{name}VersionNumber;
          
//! Project version string for #{name}.
FOUNDATION_EXPORT const unsigned char #{name}VersionString[];
          
"
        end

    end

end