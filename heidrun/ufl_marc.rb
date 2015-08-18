
def caribbean?(parser_value)
  parser_value.value.include?('Digital Library of the Caribbean')
end

def subfield_e(df)
  df['marc:subfield'].match_attribute(:code, 'e')
end

contributor_select = lambda { |df|
  (df.tag == '700' &&
    !['joint author', 'jt author'].include?(subfield_e(df))) ||
  (['710', '711', '720'].include?(df.tag) &&
    !['aut', 'cre'].include?(subfield_e(df)))
}

creator_select = lambda { |df|
  ['100', '110', '111', '700'].include?(df.tag) &&
    ['joint author.', 'jt author'].include?(subfield_e(df))
}

identifier_map = lambda { |r|
  cf_001 = MappingTools::MARC.controlfield_value(r, '001')
  df_35 = MappingTools::MARC.datafield_el(r, '035')
  df_35a = MappingTools::MARC.subfield_value(df_35, 'a')
  df_50 = MappingTools::MARC.datafield_el(r, '050')
  if !df_50.nil? && !df_50.children.empty?
    df_50ab =  df_50.children.select { |c| c.name == 'subfield' \
                                           && %w(a b).include?(c[:code]) }
                              .map { |el| el.children.first.to_s }
  else
    df_50ab = []
  end
  [cf_001, df_35a, df_50ab.join(' ')].reject { |e| e.empty? }
}


Krikri::Mapper.define(:ufl_marc, :parser => Krikri::MARCXMLParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/ufl'
    label 'University of Florida Libraries'
  end

  dataProvider :class => DPLA::MAP::Agent,
               :each => record.field('marc:datafield')
                              .match_attribute(:tag, '535'),
               :as => :dataP do
    providedLabel dataP.field('marc:subfield').match_attribute(:code, 'a')
  end

  intermediateProvider :class => DPLA::MAP::Agent,
                       :each => record.field('marc:datafield')
                                      .match_attribute(:tag, '830')
                                      .field('marc:subfield')
                                      .match_attribute(:code, 'a')
                                      .select { |a| caribbean?(a) },
                       :as => :ip do
    providedLabel ip
  end
  
  isShownAt :class => DPLA::MAP::WebResource,
            :each => record.field('marc:datafield')
                           .match_attribute(:tag, '856'),
            :as => :the_uri do
    uri the_uri.field('marc:subfield').match_attribute(:code, 'u')
  end

  preview :class => DPLA::MAP::WebResource,
          :each => record.field('marc:datafield')
                         .match_attribute(:tag, '992'),
          :as => :thumb do
    # FIXME:  ensure properly urlencoded.  There are URIs with space
    # characters that produce errors.
    uri thumb.field('marc:subfield').match_attribute(:code, 'a')
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do

    collection :class => DPLA::MAP::Collection, 
               :each => record.field('marc:datafield')
                              .match_attribute(:tag, '830'),
               :as => :coll do
      title coll.field('marc:subfield').match_attribute(:code, 'a')
    end

    # contributor:
    #   700 when the subfield e is not 'joint author' or 'jt author';
    #   710; 711; 720 when the relator term (subfield e) is not 'aut' or 'cre'
    contributor :class => DPLA::MAP::Agent,
                :each => record.field('marc:datafield')
                               .select(&contributor_select),
                :as => :contrib do
      providedLabel contrib.field('marc:subfield')
    end

    # creator:
    #   100, 110, 111, 700 when the relator term (subfield e) is
    #   'joint author.' or 'jt author'
    creator :class => DPLA::MAP::Agent,
            :each => record.field('marc:datafield')
                           .select(&creator_select),
            :as => :cre do
      providedLabel cre.field('marc:subfield')
    end

    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('marc:datafield')
                        .match_attribute(:tag, '260'),
         :as => :date do
      providedLabel date.field('marc:subfield').match_attribute(:code, 'c')
    end

    # description
    #   5XX; not 538, 535, 533, 510
    description record.field('marc:datafield')
                      .select { |df| df.tag[/^5(?!10|33|35|38)[0-9]{2}/] }
                      .field('marc:subfield')

    extent record.field('marc:datafield')
            .match_attribute(:tag) { |tag| tag == '300' || tag == '340' }
            .select { |df| (df.tag == '300' && 
                           (!df['marc:subfield'].match_attribute(:code, 'a').empty? || 
                            !df['marc:subfield'].match_attribute(:code, 'c').empty?)) ||
                      (df.tag == '340' && 
                       !df['marc:subfield'].match_attribute(:code, 'b').empty?) }
            .field('marc:subfield')

    # genre
    #   See chart here [minus step two]:
    #   https://docs.google.com/spreadsheet/ccc?key=0ApDps8nOS9g5dHBOS0ZLRVJyZ1ZsR3RNZDhXTGV4SVE#gid=0
    genre  :class => DPLA::MAP::Concept,
           :each => record.map { |r|
                      leader = MappingTools::MARC.leader_value(r)
                      cf_007 = MappingTools::MARC.controlfield_value(r, '007')
                      cf_008 = MappingTools::MARC.controlfield_value(r, '008')
                     MappingTools::MARC.genre leader: leader,
                                              cf_007: cf_007,
                                              cf_008: cf_008
                   }.flatten,
          :as => :g do
      prefLabel g
    end

    # dctype
    #   337$a
    #   See spreadsheet referenced above for genre.
    dctype :class => DPLA::MAP::Concept,
           :each => record.map { |r|

                      leader = MappingTools::MARC.leader_value(r)
                      cf_007 = MappingTools::MARC.controlfield_value(r, '007')
                      df_337 = MappingTools::MARC.datafield_el(r, '337')
                      df_337a = MappingTools::MARC.subfield_value(df_337, 'a')

                      MappingTools::MARC.dctype leader: leader,
                                                cf_007: cf_007,
                                                df_337a: df_337a
                    }.flatten,
           :as => :dct do
      prefLabel dct
    end

    # identifier
    #   001; 035$a;
    #   050$a$b (join strings with a space character)
    identifier :class => DPLA::MAP::Concept,
               :each => record.map(&identifier_map).flatten,
               :as => :id do
      providedLabel id
    end

    #language 

    #spatial 

    publisher :class => DPLA::MAP::Agent, 
              :each => record.field('marc:datafield')
                             .match_attribute(:tag, '260'),
              :as => :pub do
      providedLabel pub.field('marc:subfield').match_attribute(:code, 'b')
    end
    
    # for relation below the mapping is to both 780$t and 787$t, not sure how
    # to combine attribute mappings in an OR relationship
    relation record.field('marc:datafield').match_attribute(:tag, '780')
                   .field('marc:subfield').match_attribute(:code, 't')            
                 
    rights record.field('marc:datafield').match_attribute(:tag, '506')
                   .field('marc:subfield').match_attribute(:code, 'a')

    #subject 

    # title
    #   245 (all subfields except $c); 242; 240
    title :class => DPLA::MAP::Concept,
          :each => record.map { |r|
                     nodes = []  # Elements
                     # These appended elements will be nil if the datafields
                     # do not exist.  The array will be compacted below.
                     nodes << MappingTools::MARC.datafield_el(r, '240')
                     nodes << MappingTools::MARC.datafield_el(r, '242')
                     nodes_245 = MappingTools::MARC.datafield_el(r, '245')
                     if !nodes_245.nil? && !nodes_245.children.empty?
                       nodes += nodes_245.children
                                         .select { |c| c.name == 'subfield' \
                                                       && c[:code] != 'c' }
                     end
                     # Inside of a subfield element, you still have a
                     # `children` property with a single XML text node, so
                     # these have to be mapped to an array of strings:
                     nodes.compact.map { |n| n.children.first.to_s }
                   }.flatten,
          :as => :t do
      providedLabel t
    end

  end
end
