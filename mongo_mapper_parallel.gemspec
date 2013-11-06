Gem::Specification.new do |s|
  s.name        = 'mongo_mapper_parallel'
  s.version     = '1.0.0'
  s.date        = '2013-11-6'
  s.summary     = "Extremely fast non-blocking parallel javascripts on entire MongoDB collection with MongoMapper adapter."
  s.description = File.open(File.dirname(__FILE__)+"/README.md").read
  s.authors     = ["Jonathan Raiman"]
  s.email       = 'jraiman@mit.edu'
  s.files       = ["lib/ParallelCompiler.rb"]
  s.requirements << "MongoDB, 2.4+"
  s.requirements << "mongo_mapper"
  s.requirements << "colorize"
  s.requirements << "Parallel"
  s.add_runtime_dependency 'mongo_mapper'
  s.add_runtime_dependency 'colorize'
  s.add_runtime_dependency 'parallel'
  s.homepage    = 'http://github.org/JonathanRaiman/mongo_mapper_parallel'
  s.license     = 'MIT'
end