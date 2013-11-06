Mongo Mapper Parallel
=====================

**Mongo Mapper Parallel** can perform MapReduce-like operations on an entire collection in parallel. This is a non-blocking
operation, so the scripts can invoke database methods (`db.collection.update`, `db.collection.insert`, etc...) at blazing
speed.

Parallel processing is achieved by using [Parallel](https://github.com/grosser/parallel) and MongoDB's `splitVector` command.

Usage
-----

To get started:

	require 'mongo_mapper'
	require 'mongo_mapper_parallel'

	class User
		include MongoMapper::Document
		# your fields go here
	end

	User.connection(Mongo::Connection.new("localhost",nil, :pool_size => 10, :pool_timeout => 30))

	parallelCompiler = ParallelCompiler.new(
		:class => User,
		:split => :name,
		:args => ["Bob", "William"],
		:javascript => File.read(File.dirname(__FILE__)+"/myScript.js")
	)

	parallelCompiler.run

The Compiler takes as arguments the `class`, the `split` key you will be using (in this example *:name*), and
the javascript file you want to use as a String.

Javascript Format
-----------------

The javascript will receive as input 3 arguments:

	function (start, end, _args) {
		// your code goes here
	}

Where `_args` is whatever object you provided earlier as `args`.

Note that the *start* and *end* keys are useful for running the following operation in your scripts:

	var search_opts = {$gte: start};
	if (end) search_opts["$lte"] = end;
	db.users.find({name: search_opts}).forEach( function (el) {// etc...});

Known Issues
------------

It appears that under certain conditions a segmentation fault will occur after a while. So far the cause
is not known, but it appears this is an issue that others have reported to Mongo already, so hopefully
the next update will fix this. In the meantime you can always relaunch the calculation from the point at
which this failed.