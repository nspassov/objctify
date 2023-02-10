#
# Copyright Devexperts (2019)
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

require 'logger'

module Objctify

  class Context
    class J2ObjCSettings
      attr_accessor :distr_dir, :prefixes_file_path, :extra_cli_args
    end

    attr_accessor :project_name_param, :java_sources_param, :objc_sources_param, :project_dependencies_param, :project_frameworks_param

    attr_accessor :debug

    def initialize
      @j2objc_config = J2ObjCSettings.new
      @project_name = ''
      @dependencies = Array([])
    end

    def project_name(project_name)
      self.project_name_param = project_name
    end

    def java_sources(java_sources)
      self.java_sources_param = java_sources
    end

    def objc_sources(objc_sources)
      self.objc_sources_param = objc_sources
    end

    def dependencies(dependencies)
      self.project_dependencies_param = dependencies
    end

    def frameworks(frameworks)
      self.project_frameworks_param = frameworks
    end

    def j2objc_config
      yield(@j2objc_config) if block_given?
      @j2objc_config
    end

    # Logger setuo
    $logger = Logger.new(STDOUT)
    $logger.level = Logger::INFO

    def debug 
      $logger.level = Logger::DEBUG
    end

  end
end
