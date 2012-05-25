require "source_notes/version"

module SourceNotes
  class Extractor
    # Annotation objects are triplets <tt>:line</tt>, <tt>:tag</tt>, <tt>:text</tt> that
    # represent the line where the annotation lives, its tag, and its text. Note
    # the filename is not stored.
    #
    # Annotations are looked for in comments and modulus whitespace they have to
    # start with the tag optionally followed by a colon. Everything up to the end
    # of the line (or closing ERB comment tag) is considered to be their text.
    class Annotation < Struct.new(:line, :tag, :text)
      # Returns a representation of the annotation that looks like this:
      #
      #   [126] [TODO] This algorithm is simple and clearly correct, make it faster.
      #
      # If +options+ has a flag <tt>:tag</tt> the tag is shown as in the example above.
      # Otherwise the string contains just line and text.
      def to_s(options={})
        s = "[#{line.to_s.rjust(options[:indent])}] "
        s << "[#{tag}] " if options[:tag]
        s << text
      end
    end

    # Prints all annotations with tag +tag+ under the current PWD
    # Only filenames with extension +.builder+, +.rb+, +.erb+, +.haml+, +.slim+,
    # +.css+, +.scss+, +.js+, and +.coffee+ are taken into account.
    # The +options+ hash is passed to each
    # annotation's +to_s+.
    #
    # This class method is the single entry point for the rake tasks.
    def self.enumerate(tag, options={})
      extractor = new(tag, options)
      extractor.display(options)
    end

    attr_reader :tag

    def initialize(tag, options = {})
      @tag = tag
      @dirs = options[:dirs] || [Dir::pwd]
      @relative_path = options[:relative_path]
    end

    # Prints the mapping from filenames to annotations in +results+ ordered by filename.
    # The +options+ hash is passed to each annotation's +to_s+.
    def display(options={})
      options[:indent] = find.map { |f, a| a.map(&:line) }.flatten.max.to_s.size
      find.keys.sort.each do |file|

        if @relative_path
          puts "#{Pathname.new(file).relative_path_from(Pathname.new(@relative_path))}:"
        else
          puts "#{file}:"
        end

        find[file].each do |note|
          puts "  * #{note.to_s(options)}"
        end
        puts
      end
    end

    private

    # Returns a hash that maps filenames under +dirs+ (recursively) to arrays
    # with their annotations.
    def find
      @dirs.inject({}) { |h, dir| h.update(find_in(dir)) }
    end

    # Returns a hash that maps filenames under +dir+ (recursively) to arrays
    # with their annotations. Only files with annotations are included, and only
    # those with extension +.builder+, +.rb+, +.erb+, +.haml+, +.slim+, +.css+,
    # +.scss+, +.js+, and +.coffee+
    # are taken into account.
    def find_in(dir)
      results = {}

      Dir.glob("#{dir}/*") do |item|
        next if File.basename(item)[0] == ?.

        if File.directory?(item)
          results.update(find_in(item))
        elsif item =~ /\.(builder|rb|coffee)$/
          results.update(extract_annotations_from(item, /#\s*(#{tag}):?\s*(.*)$/))
        elsif item =~ /\.(css|scss|js)$/
          results.update(extract_annotations_from(item, /\/\/\s*(#{tag}):?\s*(.*)$/))
        elsif item =~ /\.erb$/
          results.update(extract_annotations_from(item, /<%\s*#\s*(#{tag}):?\s*(.*?)\s*%>/))
        elsif item =~ /\.haml$/
          results.update(extract_annotations_from(item, /-\s*#\s*(#{tag}):?\s*(.*)$/))
        elsif item =~ /\.slim$/
          results.update(extract_annotations_from(item, /\/\s*\s*(#{tag}):?\s*(.*)$/))
        end
      end

      results
    end

    # If +file+ is the filename of a file that contains annotations this method returns
    # a hash with a single entry that maps +file+ to an array of its annotations.
    # Otherwise it returns an empty hash.
    def extract_annotations_from(file, pattern)
      lineno = 0
      result = File.readlines(file).inject([]) do |list, line|
        lineno += 1
        next list unless line =~ pattern
        list << Annotation.new(lineno, $1, $2)
      end
      result.empty? ? {} : { file => result }
    end
  end
end
