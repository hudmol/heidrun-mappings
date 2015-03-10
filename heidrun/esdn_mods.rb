Krikri::Mapper.define(:esdn_mods, :parser => Krikri::ModsParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/esdn'
    label 'Empire State Digital Network'
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('mods:note').match_attribute(:type, 'ownership')
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url').match_attribute(:usage, 'primary display').match_attribute(:access, 'object in context')
  end

  preview :class => DPLA::MAP::WebResource do
    uri record.field('mods:location', 'mods:url').match_attribute(:access, 'preview')
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    ##
    # TODO: Crosswalk says to take collection from OAI set name/description,
    # but we need to be able harvest set titles and populate them somewhere.
    # This will just pull back the setSpec code for now.
    collection :class => DPLA::MAP::Collection, :each => header.field('xmlns:set_spec'), :as => :coll do
      title coll
    end

    contributor :class => DPLA::MAP::Agent, :each => record.field('mods:name').select { |name| name['mods:role'].map(&:value).include?('contributor') }, :as => :contrib do
      providedLabel contrib.field('mods:namePart')
    end

    creator :class => DPLA::MAP::Agent, :each => record.field('mods:name').select { |name| name['mods:role'].map(&:value).include?('creator') }, :as => :creator_role do
      providedLabel creator_role.field('mods:namePart')
    end

    date :class => DPLA::MAP::TimeSpan, :each => record.field('mods:originInfo'), :as => :created do
      providedLabel created.field('mods:dateCreated').match_attribute(:keyDate, 'yes')
      self.begin created.field('mods:dateCreated').match_attribute(:point, 'start')
      self.end created.field('mods:dateCreated').match_attribute(:point, 'end')
    end

    description record.field('mods:note').match_attribute(:type, 'content')

    extent record.field('mods:physicalDescription', 'mods:extent')

    # Selecting non-DCMIType values will be handled in enrichment
    dcformat record.field('mods:typeOfResource')

    genre record.field('mods:physicalDescription', 'mods:form')

    identifier record.field('mods:identifier')

    language :class => DPLA::MAP::Controlled::Language, :each => record.field('mods:language', 'mods:languageTerm'), :as => :lang do
      prefLabel lang
    end

    spatial :class => DPLA::MAP::Place, :each => record.field('mods:subject', 'mods:geographic'), :as => :place do
      providedLabel place
    end

    publisher :class => DPLA::MAP::Agent, :each => record.field('mods:name').select { |name| name['mods:role'].map(&:value).include?('publisher') }, :as => :pub do
      providedLabel pub.field('mods:namePart')
    end

    rights record.field('mods:accessCondition')

    subject :class => DPLA::MAP::Concept, :each => record.field('mods:subject', 'mods:topic'), :as => :subject do
      providedLabel subject
    end

    title record.field('mods:titleInfo', 'mods:title')

    # Selecting DCMIType-only values will be handled in enrichment
    dctype record.field('mods:typeOfResource')
  end
end