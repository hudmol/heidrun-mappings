require 'mapping_tools/marc/dcformat'

RSpec.describe MappingTools::MARC::DCFormat do

  describe '.assign_from_leader' do
    it 'raises a NoElementError if not given a leader' do
      expect { subject.assign_from_leader([], {}) }
        .to raise_error(MappingTools::MARC::NoElementError)
    end
  end

  describe '.assign_from_cf007' do
    it 'raises a NoElementError if not given a crontrol field 007' do
      expect { subject.assign_from_cf007([], {}) }
        .to raise_error(MappingTools::MARC::NoElementError)
    end
  end
end
