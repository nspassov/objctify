#
# Copyright Devexperts (2019)
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

module Objctify

  def self.collect_files(java_source_path)
    files_to_translate = ''
    Dir.glob(java_source_path + '/**/*.java') do |item|
      files_to_translate = files_to_translate + item + ' '
    end
    files_to_translate
  end

  def self.translate_files(java_sources, prefix_file_path, result_path, dependencies, extra_cli_args)
    files_to_translate = collect_files(java_sources)

    raise Objctify::Informative, "No files to translate, check 'java_sources' parameter in Objctifile" if files_to_translate.empty?

    source_path = ""
    unless dependencies.nil?
      dependencies.each do |javaModule|
        module_sources = File.expand_path(javaModule)
        source_path = source_path + module_sources + ':'
      end
    else
      source_path = java_sources
    end

    j2objc_call = compose_j2objc_call(source_path, prefix_file_path, result_path, extra_cli_args) + ' ' + files_to_translate
    call = system(j2objc_call)

    raise Objctify::Informative, "J2Objc call is unsuccessful: #{j2objc_call}" unless call
  end

  def self.compose_j2objc_call(java_sources, prefix_file_path, result_path, extra_cli_args)
    classpath = "j2objc_dist/lib/jsr305-3.0.0.jar"
    j2objc_call = "j2objc_dist/j2objc -source 8 --swift-friendly -l #{extra_cli_args} -d #{result_path} -classpath #{classpath} -sourcepath #{java_sources}"

    unless prefix_file_path.nil? || prefix_file_path == ''
      j2objc_call += " --prefixes #{prefix_file_path}"
    end

    j2objc_call
  end

end
