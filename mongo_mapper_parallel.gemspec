Gem::Specification.new do |s|
  s.name        = 'mongo_mapper_parallel'
  s.version     = '1.0.7'
  s.date        = '2013-11-19'
  s.summary     = "Extremely fast non-blocking parallel javascripts on entire MongoDB collection with MongoMapper adapter."
  s.description = "Mongo Mapper Parallel can perform MapReduce-like operations on an entire collection in parallel. This is a non-blocking operation, so the scripts can invoke database methods (db.collection.update, db.collection.insert, etc...) at blazing speed."
  s.authors     = ["Jonathan Raiman"]
  s.email       = 'jraiman@mit.edu'
  s.files       = ["lib/mongo_mapper_parallel.rb"]
  s.requirements << "MongoDB, 2.4+"
  s.requirements << "mongo_mapper"
  s.requirements << "colorize"
  s.requirements << "parallel"
  s.requirements << "jraiman_progressbar"
  s.add_runtime_dependency 'mongo_mapper'
  s.add_runtime_dependency 'colorize'
  s.add_runtime_dependency 'parallel'
  s.add_runtime_dependency 'jraiman_progressbar'
  s.homepage    = 'http://github.org/JonathanRaiman/mongo_mapper_parallel'
  s.license     = 'MIT'
  s.has_rdoc = 'yard'
end