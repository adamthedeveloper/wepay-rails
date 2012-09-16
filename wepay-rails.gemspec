# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "wepay-rails"
  s.version = "2.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Medeiros"]
  s.date = "2012-09-16"
  s.description = "Rails gem that interfaces with the WePay API"
  s.email = "adammede@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".travis.yml",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "app/controllers/wepay/application_controller.rb",
    "app/controllers/wepay/authorize_controller.rb",
    "app/controllers/wepay/checkout_controller.rb",
    "app/controllers/wepay/ipn_controller.rb",
    "build",
    "lib/api/account_methods.rb",
    "lib/api/checkout_methods.rb",
    "lib/generators/wepay_rails/install/install_generator.rb",
    "lib/generators/wepay_rails/install/templates/create_wepay_checkout_records.rb",
    "lib/generators/wepay_rails/install/templates/wepay.yml",
    "lib/generators/wepay_rails/install/templates/wepay_checkout_record.rb",
    "lib/helpers/controller_helpers.rb",
    "lib/wepay-rails.rb",
    "test/helper.rb",
    "test/test_wepay_rails_account_methods.rb",
    "test/test_wepay_rails_authorize.rb",
    "test/test_wepay_rails_checkout_methods.rb",
    "test/test_wepay_rails_initialize.rb",
    "wepay-rails.gemspec"
  ]
  s.homepage = "http://github.com/adamthedeveloper/wepay-rails"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.16"
  s.summary = "Rails gem that interfaces with the WePay API"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<httparty>, [">= 0"])
      s.add_development_dependency(%q<rails>, ["= 3.1.0"])
      s.add_development_dependency(%q<turn>, ["= 0.8.2"])
      s.add_development_dependency(%q<thor>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<webmock>, [">= 0"])
    else
      s.add_dependency(%q<httparty>, [">= 0"])
      s.add_dependency(%q<rails>, ["= 3.1.0"])
      s.add_dependency(%q<turn>, ["= 0.8.2"])
      s.add_dependency(%q<thor>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<webmock>, [">= 0"])
    end
  else
    s.add_dependency(%q<httparty>, [">= 0"])
    s.add_dependency(%q<rails>, ["= 3.1.0"])
    s.add_dependency(%q<turn>, ["= 0.8.2"])
    s.add_dependency(%q<thor>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<webmock>, [">= 0"])
  end
end

