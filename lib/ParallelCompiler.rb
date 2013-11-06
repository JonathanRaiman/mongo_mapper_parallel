require 'parallel'     # for parallel processing
require 'colorize'     # for colored output
require 'mongo_mapper' # for access to collections.

class ParallelCompiler
	# runs distributed computation over a mongo database.
	attr_reader   :split_keys
	attr_accessor :command_class
	attr_accessor :javascript
	attr_accessor :args

	class ParallelCompilerKey
		# the chunks
		attr_accessor :future_key
		attr_accessor :key
		attr_accessor :completed
		attr_reader   :compiler

		def initialize(opts={})
			@key        = opts[:key]
			@future_key = opts[:future_key]
			@completed  = false
			@args       = opts[:args]
		end

		def javascript;    @compiler.javascript;    end

		def args;          @compiler.args;          end

		def command_class; @compiler.command_class; end

		def compile
			search_opts = {:name => {:$gte => @key}}
			if @future_key then search_opts[:name][:$lte] = @future_key	end
			command_class.database.command({
				:"$eval" => javascript,
				:args    => [@key, @future_key, @args],
				:nolock => true
				})
			@completed = true
			puts "Completed chunk".green
		end
	end

	def get_split_keys
		@split_keys, splits = [], @command_class.database.command({splitVector: "#{@command_class.database.name}.#{@command_class.collection.name}", keyPattern: {@split.to_sym => 1}, maxChunkSizeBytes: 32*1024*1024 })["splitKeys"]
		splits.each_with_index do |split_key,k|
			@split_keys << ParallelCompilerKey.new(:compiler => self, :key => split_key[@split.to_s], :future_key => (splits[k+1] ? splits[k+1][@split.to_s] : nil))
		end
	end

	def initialize(opts={})
		@command_class = opts[:class]
		@javascript    = opts[:javascript]
		@args          = opts[:args]
		@split         = opts[:split] # name, title, etc...
		get_split_keys()
		self
	end

	def run
		total = @split_keys.length
		Parallel.each_with_index(@split_keys) do |section,k|
			if !section.completed then section.compile end
			# ProgressBar.displayPosition(k,total)
		end
		puts "Success".green
	end

end