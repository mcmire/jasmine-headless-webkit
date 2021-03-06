require 'jasmine'

module Jasmine
  class FilesList
    attr_reader :files, :filtered_files

    DEFAULT_FILES = [
      File.join(Jasmine.root, "lib/jasmine.js"),
      File.join(Jasmine.root, "lib/jasmine-html.js"),
      File.expand_path('../../../jasmine/jasmine.headless-reporter.js', __FILE__)
    ]

    def initialize(options = {})
      @options = options
      @files = DEFAULT_FILES.dup
      @filtered_files = @files.dup
      use_config! if config?

      @code_for_file = {}
    end

    def use_spec?(file)
      spec_filter.empty? || spec_filter.include?(file)
    end

    def filtered?
      files != filtered_files
    end

    def files_to_html
      to_html(files)
    end

    def filtered_files_to_html
      to_html(filtered_files)
    end

    private
    def to_html(files)
      coffeescript_run = []

      files.collect { |file|
        next @code_for_file[file] if @code_for_file[file]

        coffeescript_run << file if (ext = File.extname(file)) == '.coffee'
          
        output = []
        if (files.last == file or ext != '.coffee') and !coffeescript_run.empty?
          output << ensure_coffeescript_run!(coffeescript_run)
        end

        if ext != '.coffee'
          output << case File.extname(file)
          when '.js'
            %{<script type="text/javascript" src="#{file}"></script>}
          when '.css'
            %{<link rel="stylesheet" href="#{file}" type="text/css" />}
          end
        end

        @code_for_file[file] = output if output.length == 1

        output
      }.flatten.reject(&:empty?)
    end

    def ensure_coffeescript_run!(files)
      data = StringIO.new
      files.each { |file| data << File.read(file) }
      data.rewind

      %{<script type="text/javascript">#{CoffeeScript.compile(data)}</script>}
    rescue CoffeeScript::CompilationError => e
      files.each do |file|
        begin
          CoffeeScript.compile(fh = File.open(file))
        rescue CoffeeScript::CompilationError => ne
          puts "[%s] %s: %s" % [ 'coffeescript'.color(:red), file.color(:yellow), ne.message.to_s.color(:white) ]
          raise ne
        ensure
          fh.close
        end
      end
    rescue StandardError => e
      puts "[%s] Error in compiling one of the followng: %s" % [ 'coffeescript'.color(:red), files.join(' ').color(:yellow) ]
      raise e
    ensure
      files.clear
    end

    def spec_filter
      @options[:only] || []
    end

    def use_config!
      @filtered_files = @files.dup

      data = @options[:config].dup
      [ [ 'src_files', 'src_dir' ], [ 'stylesheets', 'src_dir' ], [ 'helpers', 'spec_dir' ], [ 'spec_files', 'spec_dir' ] ].each do |searches, root|
        if data[searches]
          data[searches].collect do |search|
            path = search
            path = File.join(data[root], path) if data[root]
            found_files = Dir[path] - @files

            @files += found_files

            if searches == 'spec_files'
              found_files = found_files.find_all { |file| use_spec?(file) }
            end
            @filtered_files += found_files
          end
        end
      end
    end

    def config?
      @options[:config]
    end
  end
end

