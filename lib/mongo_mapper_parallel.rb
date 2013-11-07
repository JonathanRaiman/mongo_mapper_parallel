# @author Jonathan Raiman
require 'parallel'            # for parallel processing
require 'colorize'            # for colored output
require 'mongo_mapper'        # for access to collections.
require 'jraiman_progressbar' # to display progress

class MongoMapperParallel
	# runs distributed computation over a Mongo collection
	
	attr_reader   :split_keys
	attr_accessor :command_class
	attr_accessor :javascript
	attr_accessor :args

	class Key
		# A chunk that will be parallelized
		attr_accessor :future_key
		attr_accessor :key
		attr_accessor :completed
		attr_reader   :compiler

		# A chunk that will be parallelized
		# 
		# @param [Hash] opts the options to create the chunk.
		# @option opts [String] :key the lower bound of the range of resources to retrieve
		# @option opts [String] :future_key the upper bound for the range of resources to retrieve
		# @option opts [MongoMapperParallel] :compiler the Parallel execution object that holds the keys, javascript, and arguments.
		#
		def initialize(opts={})
			@key        = opts[:key]
			@compiler   = opts[:compiler]
			@future_key = opts[:future_key]
			@completed  = false
		end

		# The javascript function to run on the resources
		# 
		# @return [String] The function to run.
		def javascript;    @compiler.javascript;    end

		# The arguments to pass to the Javascript function to run on the resources
		#
		# @return [Array, Hash] The arguments to pass to the javascript function
		#
		def args;          @compiler.args;          end

		# The Ruby Class representing the collection containing the resources
		#
		# @return [Class]
		def command_class; @compiler.command_class; end

		# Sends the Javascript function, the range, and the arguments to the MongoDB instance for computation via the `db.runCommand` command.
		#
		def compile
			search_opts = {:name => {:$gte => @key}}
			if @future_key then search_opts[:name][:$lte] = @future_key	end
			command_class.database.command({
				:"$eval" => javascript,
				:args    => [@key, @future_key, args],
				:nolock => true
				})
			@completed = true
			puts "Completed chunk".green
		end
	end

	# Obtains the splitVectors keys to find chunks to parallelize via the MongoDB `splitVector` command.
	#
	# @return [Array<MongoMapperParallel::Key>] the list of the keys that will be used for parallel operation
	#
	def get_split_keys
		@split_keys, splits = [], @command_class.database.command({splitVector: "#{@command_class.database.name}.#{@command_class.collection.name}", keyPattern: {@split.to_sym => 1}, maxChunkSizeBytes: @splitSize })["splitKeys"]
		splits.each_with_index do |split_key,k|
			@split_keys << MongoMapperParallel::Key.new(:compiler => self, :key => split_key[@split.to_s], :future_key => (splits[k+1] ? splits[k+1][@split.to_s] : nil))
		end
	end

	# Instantiates the parallel operation object with the right class, javascript function, and field
	#
	# @param opts [Hash] the options to initialize the parallel script.
	# @option opts [Class] :class the Mongo collection's Ruby Class to execute operations on.
	# @option opts [String] :javascript the Javascript function in String format
	# @option opts [Array, Hash] :args the arguments to pass to the Javascript function
	# @option opts [String, Symbol] :split the field to split the computation on -- typically an indexed unique property of the resources in the collection.
	# @option opts [Fixnum] :maxChunkSizeBytes the size of the chunks to parallelize. Defaults to `32*1024*1024 = 33554432`.
	# @return [MongoMapperParallel]
	#
	def initialize(opts={})
		@command_class = opts[:class]
		@javascript    = opts[:javascript]
		@args          = opts[:args]
		@split         = opts[:split] # name, title, etc...
		@splitSize     = opts[:maxChunkSizeBytes] || 32*1024*1024
		get_split_keys()
		self
	end

	# Starts the parallel processing using {https://github.com/grosser/parallel Parallel}.
	# 
	def run
		total = @split_keys.length
		Parallel.each_with_index(@split_keys) do |section,k|
			if !section.completed then section.compile end
			JRProgressBar.show(k,total)
		end
		puts "Success".green
	end

	# In case of stalled progress you can skip ahead by a percentage and mark the keys as `completed`.
	#
	# @param percentage [Float] how far along you want to advance, a value between 0.0 and 1.0
	# @return [MongoMapperParallel]
	def advance percentage
		if percentage.class != Float
			raise TypeError.new "Can only advance by a Float value."
		elsif percentage > 1.0 or percentage < 0.0
			raise RangeError.new "Can only advance by a Float between 0.0 and 1.0."
		end
		@split_keys[0..(@split_keys.length*percentage).to_i].each {|i| i.completed = true}
		self
	end

end