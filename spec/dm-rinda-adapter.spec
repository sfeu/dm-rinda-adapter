require File.dirname(__FILE__) + '/spec_helper'

dir = DataMapper.root / 'lib' / 'dm-core' / 'spec'

require dir / 'adapter_shared_spec'
require dir / 'data_objects_adapter_shared_spec'

describe 'Adapter' do
  supported_by :rinda do
    describe DataMapper::Adapters::RindaAdapter do

      it_should_behave_like 'An Adapter'

    end
  end
end
