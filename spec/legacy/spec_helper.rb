require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
$db = DataMapper::Mongo::Spec.database(:default)
include DataMapper::Mongo
