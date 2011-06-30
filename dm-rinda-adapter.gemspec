# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-rinda-adapter}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Sebastian Feuerstack}]
  s.date = %q{2011-06-30}
  s.description = %q{A datamapper adapter to connect to a rinda tuplespace}
  s.email = %q{sebastian @nospam@ feuerstack.de}
  s.extra_rdoc_files = [%q{lib/rinda-patch.rb}, %q{lib/rinda_adapter.rb}]
  s.files = [%q{Manifest}, %q{Rakefile}, %q{lib/rinda-patch.rb}, %q{lib/rinda_adapter.rb}, %q{spec/legacy/README}, %q{spec/legacy/adapter_shared_spec.rb}, %q{spec/legacy/spec_helper.rb}, %q{spec/lib/adapter_helpers.rb}, %q{spec/lib/collection_helpers.rb}, %q{spec/lib/counter_adapter.rb}, %q{spec/lib/pending_helpers.rb}, %q{spec/lib/rspec_immediate_feedback_formatter.rb}, %q{spec/rcov.opts}, %q{spec/rinda-adapter_spec.rb}, %q{spec/spec.opts}, %q{spec/spec_helper.rb}, %q{dm-rinda-adapter.gemspec}]
  s.homepage = %q{http://github.com/sfeu/dm-rinda-adapter}
  s.rdoc_options = [%q{--line-numbers}, %q{--inline-source}, %q{--title}, %q{Dm-rinda-adapter}, %q{--main}, %q{README.rdoc}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{dm-rinda-adapter}
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{A datamapper adapter to connect to a rinda tuplespace}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
