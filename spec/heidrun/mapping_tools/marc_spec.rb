require 'mapping_tools/marc'

RSpec.describe MappingTools::MARC do

  shared_context 'with record' do
    let(:record) { double }
    let(:node) { double }
    let(:children) { [] }
    before do
      allow(record).to receive(:node).and_return(node)
      allow(node).to receive(:children).and_return(children)
    end
  end

  shared_context 'with subfields' do
    let(:el1) { double }
    let(:el2) { double }
    let(:el3) { double }
    let(:sfa1) { double }
    let(:sfa2) { double }
    let(:sf_bad) { double }
    let(:sfchild1) { double }
    let(:sfchild2) { double }
    let(:elements) { [el1, el2, el3] }

    before do
      allow(el1).to receive(:children).and_return([sfa1])
      allow(el2).to receive(:children).and_return([sfa2])
      allow(el3).to receive(:children).and_return([sf_bad])

      allow(sfa1).to receive(:name).and_return('subfield')
      allow(sfa2).to receive(:name).and_return('subfield')
      allow(sf_bad).to receive(:name).and_return('subfield')

      allow(sfa1).to receive(:[]).with(:code).and_return('a')
      allow(sfa2).to receive(:[]).with(:code).and_return('a')
      allow(sf_bad).to receive(:[]).with(:code).and_return('1')

      allow(sfa1).to receive(:children).and_return(sfchild1)
      allow(sfa2).to receive(:children).and_return(sfchild2)

      allow(sfchild1).to receive(:first).and_return('sfa1')
      allow(sfchild2).to receive(:first).and_return('sfa2')
    end
  end

  context 'when generating a block for Array#select' do
    let(:controlfield) { double }
    let(:notwanted1) { double }
    let(:notwanted2) { double }
    let(:fields) { [controlfield, notwanted1, notwanted2] }
    before do
      allow(controlfield).to receive(:name).and_return('controlfield')
      allow(controlfield).to receive(:[]).with(:tag).and_return('007')

      allow(notwanted1).to receive(:name).and_return('x')

      allow(notwanted2).to receive(:name).and_return('controlfield')
      allow(notwanted2).to receive(:[]).with(:tag).and_return('001')
    end

    describe '.name_tag_condition' do
      it 'returns a lambda that works in a select' do
        f = fields.select(&subject.name_tag_condition('controlfield', '007'))
                  .first
        expect(f).to eq(controlfield)
      end
    end

    describe '.name_tag_match_condition' do
      it 'returns a lambda that works in a select' do
        f = fields.select(&subject.name_tag_match_condition('controlfield',
                                                            /^\d{3}$/))
                  .first
        expect(f).to eq(controlfield)
      end
    end
  end

  context 'when generating a block for Array#select on a subfield' do
    let(:subfield) { double }
    let(:notwanted) { double }
    let(:fields) { [subfield, notwanted] }
    before do
      allow(subfield).to receive(:name).and_return('subfield')
      allow(subfield).to receive(:[]).with(:code).and_return('a')

      allow(notwanted).to receive(:name).and_return('subfield')
      allow(notwanted).to receive(:[]).with(:code).and_return('b')
    end

    describe '.subfield_code_condition' do
      it 'returns a lambda that works in a select' do
        f = fields.select(&subject.subfield_code_condition('a')).first
        expect(f).to eq(subfield)
      end
    end
  end

  describe '.select_field' do
    include_context 'with record'

    it 'evaluates string equality when given a string' do
      expect(subject).to receive(:name_tag_condition)
      subject.select_field(record, 'controlfield', '007')
    end

    it 'does a regular expression match when given a regular expression' do
      expect(subject).to receive(:name_tag_match_condition)
      subject.select_field(record, 'controlfield', /^\d{3}$/)
    end
  end

  context 'when asked to find nonexistent elements' do
    before do
      allow(subject).to receive(:select_field).and_return([])
    end

    describe '.datafield_values' do
      it 'returns [] if no elements exist with the given tag' do
        expect(subject.datafield_values(double, '000')).to eq([])
      end
    end

    describe '.controlfield_value' do
      it 'throws a NoElementError if the given control field does not exist' do
        expect { subject.controlfield_value(double, '000') }
          .to raise_error(MappingTools::MARC::NoElementError)
      end
    end

    describe '.leader_value' do
      include_context 'with record'

      it 'throws a NoElementError if the MARC leader is absent' do
        expect { subject.leader_value(record) }
          .to raise_error(MappingTools::MARC::NoElementError)
      end
    end
  end

  describe '.subfield_values' do
    include_context 'with subfields'

    it 'returns an array of subfield value strings' do
      expect(subject.subfield_values(elements, 'a')).to eq(['sfa1', 'sfa2'])
    end

    it 'returns an empty array if the subfield can not be found' do
      expect(subject.subfield_values(elements, 'b')).to eq([])
    end
  end

  describe '.all_subfield_values' do
    include_context 'with subfields'
    let(:elements_bad) { [el3] }

    it 'returns an array of all subfield value strings' do
      expect(subject.all_subfield_values(elements)).to eq(['sfa1', 'sfa2'])
    end

    it 'returns an empty array if there are no valid subfields' do
      expect(subject.all_subfield_values(elements_bad)).to eq([])
    end
  end

  context 'when evaluating particular control field codes' do
    describe '.film_video?' do
      it 'detects that the string signifies film or video' do
        %w(xc xd xf xo).each do |s|
          expect(subject.film_video?(s)).to eq(true)
        end
        expect(subject.film_video?('xx')).to eq(false)
      end
    end
  end
end