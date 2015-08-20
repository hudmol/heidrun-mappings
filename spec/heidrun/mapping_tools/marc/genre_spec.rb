require 'mapping_tools/marc/genre'

RSpec.describe MappingTools::MARC::Genre do

  let(:genres) { [] }

  describe '.assign_language' do

    it 'evaluates monograph correctly' do
      allow(subject).to receive(:language_material?).and_return(true)
      allow(subject).to receive(:monograph?).and_return(true)
      allow(subject).to receive(:serial?).and_return(false)
      allow(subject).to receive(:newspapers?).and_return(false)
      allow(subject).to receive(:mono_component_part?).and_return(false)

      subject.assign_language(genres, { leader: 'x' })
      expect(genres).to eq(['Book'])
    end

    it 'evaluates newspaper correctly' do
      allow(subject).to receive(:language_material?).and_return(true)
      allow(subject).to receive(:monograph?).and_return(false)
      allow(subject).to receive(:serial?).and_return(true)
      allow(subject).to receive(:newspapers?).and_return(true)
      allow(subject).to receive(:mono_component_part?).and_return(false)

      subject.assign_language(genres, { leader: 'x' })
      expect(genres).to eq(['Newspapers'])
    end

    it 'evaluates serial correctly' do
      allow(subject).to receive(:language_material?).and_return(true)
      allow(subject).to receive(:monograph?).and_return(false)
      allow(subject).to receive(:serial?).and_return(true)
      allow(subject).to receive(:newspapers?).and_return(false)
      allow(subject).to receive(:mono_component_part?).and_return(false)

      subject.assign_language(genres, { leader: 'x' })
      expect(genres).to eq(['Serial'])
    end

    it 'evaluates monograph component part correctly' do
      allow(subject).to receive(:language_material?).and_return(true)
      allow(subject).to receive(:monograph?).and_return(false)
      allow(subject).to receive(:serial?).and_return(false)
      allow(subject).to receive(:newspapers?).and_return(false)
      allow(subject).to receive(:mono_component_part?).and_return(true)

      subject.assign_language(genres, { leader: 'x' })
      expect(genres).to eq(['Book'])
    end

    it 'defaults to "Serial" for language material' do
      allow(subject).to receive(:language_material?).and_return(true)
      allow(subject).to receive(:monograph?).and_return(false)
      allow(subject).to receive(:serial?).and_return(false)
      allow(subject).to receive(:newspapers?).and_return(false)
      allow(subject).to receive(:mono_component_part?).and_return(false)

      subject.assign_language(genres, { leader: 'x' })
      expect(genres).to eq(['Serial'])
    end

    it 'returns true if it can determine the genre' do
      expect(subject.assign_language(genres, { leader: 'xxxxxxam' }))
        .to eq(true)
    end

    it 'returns false if it can not determine the genre' do
      expect(subject.assign_language(genres, { leader: 'x' })).to eq(false)
    end
  end


end
