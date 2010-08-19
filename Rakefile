require 'rubygems'
require 'rake'
require 'echoe'

def with_gem(gemname, &blk)
  begin
    require gemname
    blk.call
  rescue LoadError => e
    puts "Failed to load gem #{gemname} because #{e}."
  end
end

Echoe.new('dm-rinda-adapter', '0.1.0') do |p|
  p.description    = "A datamapper adapter to connect to a rinda tuplespace"
  p.url            = "http://github.com/sfeu/dm-rinda-adapter"
  p.author         = "Sebastian Feuerstack"
  p.email          = "sebastian @nospam@ feuerstack.de"
  p.ignore_pattern = ["tmp/*", "script/*","#*.*#"]
  p.development_dependencies = []
end

with_gem 'spec/rake/spectask' do
  
  desc 'Run all specs'
  Spec::Rake::SpecTask.new(:spec) do |t|
    t.spec_opts << '--options' << 'spec/spec.opts' if File.exists?('spec/spec.opts')
    t.libs << 'lib'
    t.spec_files = FileList['spec/**_spec.rb']
  end
 
  desc 'Default: Run Specs'
  task :default => :spec
 
  desc 'Run all tests'
  task :test => :spec
 
end
 
with_gem 'yard' do
  desc "Generate Yardoc"
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb', 'README.markdown']
  end
end
