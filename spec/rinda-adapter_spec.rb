require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'legacy/adapter_shared_spec'))

require "rinda/tuplespace"
require 'thread'

describe 'Adapter' do
   supported_by :rinda do
   describe DataMapper::Adapters::RindaAdapter do
      
      it_should_behave_like 'An Adapter'
      
      before(:all) do
        DataMapper.setup(:default, { :adapter => "Rinda",:local =>Rinda::TupleSpace.new})
        #DataMapper::Logger.new("data.log", :debug)
      end   

      describe '#notify' do
        before do
          @heffalump = Heffalump.create(:color => 'indigo')
          @heffalump.save
          
          class ::Receiver
              attr_accessor :results
              def initialize()
                @results=Queue.new
              end
              
              def callback_method(result)
                @results << result
#                puts "color> #{result.color}"
              end
            end
        end

       it 'should respond on changed element after subscription' do
          @heffalump.color = 'black'
          @receiver = Receiver.new()
          
          Heffalump.notify("write", { :color =>"black" },@receiver.method(:callback_method))    
          @heffalump.save
          
          @receiver.results.pop.should == @heffalump
        end
        
        it 'should properly respond to  double element #update#  after subscription by notify' do
       
          @receiver = Receiver.new()
            
          Heffalump.notify("write", { :color =>"black" },@receiver.method(:callback_method))    
          Heffalump.notify("write", { :color =>"green" },@receiver.method(:callback_method))    
            
          100.times do
            @heffalump.update(:color => 'black')
            @heffalump.update(:color => 'green')  
          end

          @receiver.results.length.should == 199 # warum? ist erstes elemen = 0
            
          100.times do 
            @receiver.results.pop.color.should == "black"
            @receiver.results.pop.color.should == "green"
          end
        end  
        
        it 'should properly respond to  double element #create#  after subscription by notify' do
       
          @receiver = Receiver.new()
            
          Heffalump.notify("write", { :color =>"black" },@receiver.method(:callback_method))    
          Heffalump.notify("write", { :color =>"green" },@receiver.method(:callback_method))    
            
          100.times do
            Heffalump.create(:color => 'black').save
            Heffalump.create(:color => 'green').save
          end

          @receiver.results.length.should == 199 # warum? ist erstes element = 0 ?
            
          100.times do 
            @receiver.results.pop.color.should == "black"
            @receiver.results.pop.color.should == "green"
          end
        end  
      end
    end
  end
end

