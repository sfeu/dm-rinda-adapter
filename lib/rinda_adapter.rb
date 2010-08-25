require 'dm-core'
gem 'dm-core', '>=0.10.0'
require "rinda/tuplespace"
require 'monitor'
require 'rinda-patch'

module DataMapper
   
  class Repository
    def notify(action,query,callback,model,dm_query)
      adapter.notify(action,query,callback,model,dm_query)
    end
   end
  
  module Model
    def notify(action,query,callback)
      q = scoped_query(query)
      q.repository.notify(action,query,callback,self,q)
    end
  end
  
  module Adapters
   
    #monkey patching new notification methods
     class AbstractAdapter
       def notify(action,query,callback,model,dm_query)
         raise NotImplementedError, "#{self.class}#notify not implemented"
       end
     end # class AbstractAdapter
    
    # This is probably the simplest functional adapter possible. It simply
    # stores and queries from a hash containing the model classes as keys,
    # and an array of hashes. It is not persistent whatsoever; when the Ruby
    # process finishes, everything that was stored it lost. However, it doesn't
    # require any other external libraries, such as data_objects, so it is ideal
    # for writing specs against. It also serves as an excellent example for
    # budding adapter developers, so it is critical that it remains well documented
    # and up to date.
    class RindaAdapter < AbstractAdapter
      #include MonitorMixin
      
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
        name = self.name
    #    DataMapper.logger <<  "create #{resources.first.model}"
                
        resources.each do |resource|
          model      = resource.model
          serial     = model.serial(name)
 
          #  DataMapper.logger <<  "res #{resource.inspect}"
          #initialize_serial(resource, rand(2**32))
          #DataMapper.logger <<  "att #{resource.attributes(:field).inspect}"
          
          saveblock = { }
          
          resource.attributes.each do |key, value|
       #     DataMapper.logger <<  "before convert #{resource.model.properties[key].type}"
            saveblock[key.to_s]=convert_to_ts(resource.model.properties[key].type, value)
          end
#          model      = resource.model
 #         attributes = resource.dirty_attributes
          
   #       model.properties_with_subclasses(name).each do |property|
     #       next unless attributes.key?(property)
            
       #     value = attributes[property]
        #    saveblock[property.field.to_s]=convert_to_ts(property.type, value)
          #end  
          # add model name to be included into tuple
          saveblock["_model_"]=resources.first.model.storage_name(name).to_s

         DataMapper.logger <<  "write #{saveblock.inspect}"
          @monitor.synchronize do
            if serial
              id = @ts.writeID saveblock
              serial.set!(resource, id)
            else
              @ts.write saveblock
            end
          
          #  @ts.write saveblock
            #initialize_serial(resource,id)
          end
        
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
       
        
#        DataMapper.logger <<  "query #{query.model.to_s}"
 #       DataMapper.logger <<  "query #{query.fields.inspect}"
        queryblock = generate_query_with_conditions(query)
        DataMapper.logger <<  "ts query #{queryblock.inspect}"
        result=@ts.read_all(queryblock)
        
        DataMapper.logger <<  "result  #{result.inspect}"
        #Kernel.const_get(s)

        query.fields.each do |property|
          if (property.type == DataMapper::Types::Discriminator)
            
            key = property.name.to_s
            result.each do |entry|
                        entry[key]=eval(entry[key].to_s)
            end
          end
        end
#         DataMapper.logger <<  "result after  transformation of discriminators  #{result.inspect}"
        
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
        query = collection.query
        
        query = generate_query_with_conditions(query)
        # generate_query(collection.model)
        
        records_to_delete=[]
        @monitor.synchronize do 
          result=@ts.read_all(query)
          
          records_to_delete = collection.query.filter_records(result)
          
          records_to_delete.each do |record|
            result=@ts.take(record)
            saveblock ={ }
            attributes.each do |key, value|
              #   DataMapper.logger <<  "key: #{key.name} value: #{value}"
              saveblock[key.name.to_s]=convert_to_ts(key.name, value)
            end 
            new = result.merge  saveblock
            @ts.write(new)
            
            DataMapper.logger <<  "replaced: #{result.inspect} with: #{new.inspect}"
          end
        end # class synchronize

        return records_to_delete.size  
        #end # class mutex synchronize
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
        #DataMapper.logger <<  "delete #{collection.model.to_s}"
        query = generate_query(collection.model)
        # @mutex.synchronize do
          
          result=@ts.read_all(query)
        
          records_to_delete = collection.query.filter_records(result)
          #DataMapper.logger <<  "entries to delete #{records_to_delete.inspect}"
        
          records_to_delete.each do |record|
            result=@ts.take(record)
          end
        records_to_delete.size
        #end # class mutex synchronize
      end

      def notify(action,query,callback,model,dm_query)
        observer = notifyInternal(model, action, query)
        x = Thread.start do
          DataMapper.logger <<  "waiting on #{model.to_s} model new #{action} changes with a state change to #{query.inspect}"
          
          observer.each do |e,t|
            @monitor.synchronize {        
              DataMapper.logger <<  "TRIGGERED on #{model.to_s} model new #{action} changes with a state change to #{query.inspect}"
              
              if check_descendents(model,t) # quick patch that belongs into tuplespace 
                DataMapper.logger <<   "#{e} change detected for #{t.inspect}"
                resource = nil

                repository = dm_query.repository
                model      = dm_query.model
                identity_fields = model.key(repository.name).map &:name
                
                DataMapper.logger <<   "rep: #{repository.name}  model:#{model} identifier key: #{identity_fields.inspect}"
                
                retrieve = identity_fields.map do |x| t[x.to_s] end
                
                resource = model.get(*retrieve)
                DataMapper.logger <<   "found resource  #{resource.inspect}"

                callback.call resource
              end
            } 
          end 
        end 
        return x
      end

      private
      
      # Returns a tupleSpace Observer that waits for an {action} bason on a hash of 
      # {conditions}
      def notifyInternal(model,action,conditions)
        query = generate_query(model)
        DataMapper.logger <<  "notify query generated #{query.inspect}"
#        DataMapper.logger <<  "notify query generated11111 #{resource.attributes.inspect}"
        
        # ressource.attributes.key?("classtype")
            
       #     value = attributes[property]
        
        newconditions={}
        #newconditions["classtype"]=resource.attributes[:classtype].to_s
        conditions.each do |key, value|
            newconditions[key.to_s]=value.to_s
          end 
        query = query.merge newconditions
        DataMapper.logger <<  "notify query after merge of conditions #{query.inspect}"
        
        @ts.notify action,query
      end
     
          def check_descendents (model,result)
            if (result["classtype"].nil?) # in case there is no inheritanence relationship
              return true
            end
      descendents = model.descendants.to_ary
      
        # transform array to hash for quicker lookup
      desc_lookup = Hash[*descendents.collect { |v|
               [v.to_s, v.to_s]
             }.flatten]
      # p " identified following  descendents  #{desc_lookup.inspect}"
         #result = {"classtype" => nil }
       return  desc_lookup[result["classtype"]]
    end

      
      def generate_query(model)
        queryblock={ }
        queryblock["_model_"]=model.storage_name(name).to_s
        model.properties.each do |property|
          queryblock[property.name.to_s]=nil
        end 
        queryblock
      end
      
      def generate_query_with_conditions(query)
        model = query.model
       
        queryblock={ }
        queryblock["_model_"]=model.storage_name(name).to_s
        
#        properties = model.properties       
#        properties.each do |property|
        query.fields.each do |property|
          queryblock[property.field.to_s]=nil
        end 
        
   #     DataMapper.logger << "Conditions #{query.conditions.inspect}"
               
        conditions_statement(query.conditions, queryblock )
       
      end
     
      def comparison_statement(comparison,queryblock,negate=false)
                
        value   = comparison.value

        if comparison.slug == :eql and not comparison.relationship?
     #     DataMapper.logger << "comparison with eql #{comparison.inspect}"

          if not negate 
            subject = comparison.subject            
            column_name = subject.field
            queryblock[column_name]=value
          end

#        elsif comparison.relationship?
#          DataMapper.logger << "comparison with relationship #{comparison.inspect}"

 #         if value.respond_to?(:query) && value.respond_to?(:loaded?) && !value.loaded?
   #         return subquery(value.query, subject, qualify)
     #     else
       #     return conditions_statement(comparison.foreign_key_mapping, queryblock)
        #  end
        end
        return queryblock
      end
      
      def conditions_statement(conditions,queryblock, negate = false)
        case conditions
        when Query::Conditions::NotOperation then negate_operation(conditions.operand, queryblock,negate)
        when Query::Conditions::AbstractOperation  then operation_statement(conditions,queryblock,negate)
        when Query::Conditions::AbstractComparison then comparison_statement(conditions,queryblock,negate)
        when Array
          statement, bind_values = conditions  # handle raw conditions
          [ "(#{statement})", bind_values ].compact
     
      else
        return queryblock
      end 
      end
      
      # @api private
      def operation_statement(operation,queryblock,negate=false)
        operation.each do |operand|
          # DataMapper.logger << "operation #{operand.inspect}"
          queryblock = conditions_statement(operand,queryblock,negate)
        end
        return queryblock
      end

             # @api private
        def negate_operation(operand, queryblock,negate)
          if negate
            return  conditions_statement(operand, queryblock,false)    
          else
            return  conditions_statement(operand, queryblock,true)    
          end
          
          #statement = "NOT(#{statement})" unless statement.nil?
          # [ statement, bind_values ]
        #  return queryblick
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
        if (@options[:local])
          @ts = @options[:local]
        else
        @ts = DRbObject.new(nil, "druby://#{@options[:host]}:#{@options[:port]}")
       end
           @monitor = Monitor.new
      end
      
      def convert_to_ts(key,value)
#        DataMapper.logger <<  "key1 #{key.inspect} convert #{value.inspect} class #{value.class}"        
                 
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
