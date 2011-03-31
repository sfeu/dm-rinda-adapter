# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-rinda-adapter}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sebastian Feuerstack"]
  s.date = %q{2011-02-11}
  s.description = %q{A datamapper adapter to connect to a rinda tuplespace}
  s.email = %q{sebastian @nospam@ feuerstack.de}
  s.extra_rdoc_files = ["lib/rinda-patch.rb", "lib/rinda_adapter.rb"]
  s.files = ["Manifest", "Rakefile", "lib/rinda-patch.rb", "lib/rinda_adapter.rb", "spec/legacy/README", "spec/legacy/adapter_shared_spec.rb", "spec/legacy/spec_helper.rb", "spec/lib/adapter_helpers.rb", "spec/lib/collection_helpers.rb", "spec/lib/counter_adapter.rb", "spec/lib/pending_helpers.rb", "spec/lib/rspec_immediate_feedback_formatter.rb", "spec/rcov.opts", "spec/rinda-adapter_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "dm-rinda-adapter.gemspec"]
  s.homepage = %q{http://github.com/sfeu/dm-rinda-adapter}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Dm-rinda-adapter"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dm-rinda-adapter}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A datamapper adapter to connect to a rinda tuplespace}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
