require 'dm-core'
gem 'dm-core', '>=0.10.0'
require "rinda/tuplespace"

module DataMapper
  module Adapters
    # This is probably the simplest functional adapter possible. It simply
    # stores and queries from a hash containing the model classes as keys,
    # and an array of hashes. It is not persistent whatsoever; when the Ruby
    # process finishes, everything that was stored it lost. However, it doesn't
    # require any other external libraries, such as data_objects, so it is ideal
    # for writing specs against. It also serves as an excellent example for
    # budding adapter developers, so it is critical that it remains well documented
    # and up to date.
    class RindaAdapter < AbstractAdapter
      # Used by DataMapper to put records into a data-store: "INSERT" in SQL-speak.
      # It takes an array of the resources (model instances) to be saved. Resources
      # each have a key that can be used to quickly look them up later without
      # searching, if the adapter supports it.
      #
      # @param [Enumerable(Resource)] resources
      #   The set of resources (model instances)
      #
      # @api semipublic
      def create(resources)
        DataMapper.logger <<  "create #{resources.first.model}"

        resources.each do |resource|
        
          DataMapper.logger <<  "res #{resource.inspect}"
          initialize_serial(resource, rand(2**32))
          DataMapper.logger <<  "att #{resource.attributes(:field).inspect}"
          
          saveblock = { }
          
          resource.attributes.each do |key, value|
            DataMapper.logger <<  "before convert #{resource.model.properties[key].type}"
            saveblock[key.to_s]=convert_to_ts(resource.model.properties[key].type, value)
          end 
          # add model name to be included into tuple
          saveblock["_model_"]=resources.first.model.storage_name(name).to_s

          DataMapper.logger <<  "write #{saveblock.inspect}"
          @ts.write saveblock
        end
      end

      # Looks up one record or a collection of records from the data-store:
      # "SELECT" in SQL.
      #
      # @param [Query] query
      #   The query to be used to seach for the resources
      #
      # @return [Array]
      #   An Array of Hashes containing the key-value pairs for
      #   each record
      #
      # @api semipublic
      def read(query)
       
        
        DataMapper.logger <<  "query #{query.model.to_s}"
        DataMapper.logger <<  "query #{query.fields.inspect}"
        queryblock = generate_query(query.model)
        DataMapper.logger <<  "ts query #{queryblock.inspect}"
        result=@ts.read_all(queryblock)
        
        DataMapper.logger <<  "result  #{result.inspect}"
        #Kernel.const_get(s)

        query.fields.each do |property|
          if (property.type == DataMapper::Types::Discriminator)
            key = property.name.to_s
            result.each do |entry|
              entry[key]=eval(entry[key])
            end
          end
        end
         DataMapper.logger <<  "result after  transformation of discriminators  #{result.inspect}"
        
        query.filter_records(result)
      end

      # Used by DataMapper to update the attributes on existing records in a
      # data-store: "UPDATE" in SQL-speak. It takes a hash of the attributes
      # to update with, as well as a collection object that specifies which resources
      # should be updated.
      #
      # @param [Hash] attributes
      #   A set of key-value pairs of the attributes to update the resources with.
      # @param [DataMapper::Collection] resources
      #   The collection of resources to update.
      #
      # @api semipublic
      def update(attributes, collection)
        DataMapper.logger <<  "update attributes: #{attributes.inspect} collection: #{collection.inspect}"
        
        query = generate_query(collection.model)
        result=@ts.read_all(query)
        
        records_to_delete = collection.query.filter_records(result)
        
        records_to_delete.each do |record|
          result=@ts.take(record)
          saveblock ={ }
          attributes.each do |key, value|
             DataMapper.logger <<  "key: #{key.name} value: #{value}"
            saveblock[key.name.to_s]=convert_to_ts(key.name, value)
          end 
          new = result.merge  saveblock
          @ts.write(new)
          DataMapper.logger <<  "replaced: #{result.inspect} with: #{new.inspect}"
        end
        records_to_delete.size
      end

      # Destroys all the records matching the given query. "DELETE" in SQL.
      #
      # @param [DataMapper::Collection] resources
      #   The collection of resources to delete.
      #
      # @return [Integer]
      #   The number of records that were deleted.
      #
      # @api semipublic
      def delete(collection)
        DataMapper.logger <<  "delete #{collection.model.to_s}"
        query = generate_query(collection.model)
        result=@ts.read_all(query)
        
        records_to_delete = collection.query.filter_records(result)
        DataMapper.logger <<  "entries to delete #{records_to_delete.inspect}"
        
        records_to_delete.each do |record|
          result=@ts.take(record)
        end
        records_to_delete.size
      end

      private
      
      def generate_query(model)
        queryblock={ }
        queryblock["_model_"]=model.storage_name(name).to_s
        model.properties.each do |property|
          queryblock[property.name.to_s]=nil
        end 
        queryblock
      end

      # Make a new instance of the adapter. The @records ivar is the 'data-store'
      # for this adapter. It is not shared amongst multiple incarnations of this
      # adapter, eg DataMapper.setup(:default, :adapter => :in_memory);
      # DataMapper.setup(:alternate, :adapter => :in_memory) do not share the
      # data-store between them.
      #
      # @param [String, Symbol] name
      #   The name of the Repository using this adapter.
      # @param [String, Hash] uri_or_options
      #   The connection uri string, or a hash of options to set up
      #   the adapter
      #
      # @api semipublic
      def initialize(name, options = {})
        super
        @records = {}
               
        @ts = DRbObject.new(nil, "druby://#{@options[:host]}:#{@options[:port]}")
      end
      
      def convert_to_ts(key,value)
        DataMapper.logger <<  "key1 #{key.inspect} convert #{value.inspect} class #{value.class}"        
                 
        if (key== DataMapper::Types::Discriminator)
          return value.to_s
        else
          return value
        end 
      end
      
    end # class InMemoryAdapter

    const_added(:RindaAdapter)
  end # module Adapters
end # module DataMapper
