module Rinda # dirty monkey patching to retrieve unique running ID, primitiv einc beacuse touble nested tuplebag storage with symbols. 

  class TupleSpace
   
     def initialize(period=60)
      super()
      @bag = TupleBag.new
      @read_waiter = TupleBag.new
      @take_waiter = TupleBag.new
      @notify_waiter = TupleBag.new
      @period = period
      @keeper = nil
       @id = 0
    end
    
    
    def writeID(tuple,sec=nil)
      synchronize do
        @id =@id+1
        tuple["id"] = @id
        write(tuple,sec)
        @id
      end
    end
  end
end
