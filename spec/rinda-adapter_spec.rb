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
      
      
      describe 'inheritenence' do

        before :all do
          
          class Element
            include DataMapper::Resource
            property :id, Serial # the serial id is required as the first key since otherwise the sorting does not work as expected. (it would be ordered by ascending names - the second key!
            property :type, Discriminator
            property :name, String, :key => true
          end
          
          class Layoutelement < Element
            property :size, String
            property :pos, Integer
            belongs_to :layoutcontainer # defaults to :required => true
          end

          class Layoutcontainer < Layoutelement
            has n, :layoutelements
          end
        end
        before(:each) do
          DataMapper.setup(:default, { :adapter => "Rinda",:local =>Rinda::TupleSpace.new})
          #DataMapper::Logger.new("data.log", :debug)
        end   
        
        it 'should preserve the order ' do
          p = Layoutcontainer .new(:name => "container")
          c1= Layoutcontainer.new(:name =>"a_comment_1")
          c2=Layoutcontainer.new(:name => "x_comment_2")
          c1.layoutelements=[]
          p.layoutelements =[c2,c1]
          p.save
          Layoutelement.first(:name =>"container").layoutelements.should == [c2,c1]
        end
        
        it 'should preserve the order even after attribute update' do
          p = Layoutcontainer .new(:name => "container")
          c1= Layoutcontainer.new(:name =>"a_comment_1")
          c2=Layoutcontainer.new(:name => "x_comment_2")
          c4 =Layoutcontainer.new(:name => "x_child1")
          c5 = Layoutcontainer.new(:name => "a_child2")
          c1.layoutelements=[]
          p.layoutelements =[c2,c1]
          c1.layoutelements=[c4,c5]
          p.save
          up = Layoutelement.first(:name=>"a_comment_1")
          up.update(:size =>"test")
          
          Layoutelement.first(:name =>"container").layoutelements.should == [c2,up]
          Layoutelement.first(:name =>"container").layoutelements[1].layoutelements.should == [c4,c5]
        end
       
        it 'should preserve the order in the structure after save and find even for large arrays' do
          p = Layoutcontainer .new(:name => "container",:layoutelements => [])
          for i in 0..30
            c = Layoutcontainer.new(:name => "name_#{i}", :pos=>i)
            for j in 0..30
              c.layoutelements << Layoutelement.new(:name =>"child_#{j}", :pos =>j)
            end
            p.layoutelements  <<  c
          end       

          old = p.layoutelements
          
          p.save
                  
          test = Layoutelement.first(:name=>"container").layoutelements
          
          test.each_with_index do |e,i| 
            e.pos.should == i
            e.layoutelements.each_with_index do |f,j|
              f.pos.should == j
            end
          end
        end
      end
    end
  end
end

