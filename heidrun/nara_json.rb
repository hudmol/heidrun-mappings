def nara_catalog_uri(id)
  "http://catalog.archives.gov/id/#{id.node}"
end

Krikri::Mapper.define(:nara_json, :parser => Krikri::JsonParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/nara'
    label 'National Archives and Records Administration'
  end

  dataProvider :class => DPLA::MAP::Agent do
    providedLabel record.field('description', 'item | itemAv | fileUnit',
                               'physicalOccurrenceArray',
                               'itemPhysicalOccurrence |' \
                                 'itemAvPhysicalOccurrence |' \
                                 'fileUnitPhysicalOccurrence',
                               'referenceUnitArray', 'referenceUnit',
                               'name')
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('naId').first_value.map { |id| nara_catalog_uri(id) }
  end

  # FIXME:
  #
  # The following `object` and `preview` mappings can result in multiple
  # objects with NARA, and you'll get an error like this if there are more than
  # one:
  #     Error mapping #<Krikri::JsonParser:0x007fb8a7bbb360>, default   URI must be
  #     set to a single value; got ["https://catalog.archives.gov/OpaAPI/media/6050582/content/rediscovery/24513-2011-001-pr.jpg",
  #     "https://catalog.archives.gov/OpaAPI/media/6050582/content/rediscovery/24513.pdf",
  #     "https://catalog.archives.gov/OpaAPI/media/6050582/content/rediscovery/24513-2011-002-pr.jpg"]
  # (This error was for https://catalog.archives.gov/api/v1?naIds=6050582&pretty=false&resultTypes=item,fileUnit&objects.object.@objectSortNum=1)
  #
  # object :class => DPLA::MAP::WebResource,
  #        :each => record.field('objects', 'object'),
  #        :as => :obj do
  #   uri obj.field('file', '@url')
  #   dcformat obj.field('file', '@mime')
  # end
  #
  # preview :class => DPLA::MAP::WebResource,
  #        :each => record.field('objects', 'object'),
  #        :as => :obj do
  #   uri obj.field('thumbnail', '@url')
  #   dcformat obj.field('thumbnail', '@mime')
  # end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do

    # <parentRecordGroup> OR <parentCollection>
    #   <naId>[VALUE]</naId>
    #   <title>[VALUE]</title>
    #   <recordGroupNumber>[VALUE]</recordGroupNumber>
    # </parentRecordGroup> OR </parentCollection>
    collection :class => DPLA::MAP::Collection do
      title record.field('description', 'item | itemAv | fileUnit',
                         'parentSeries',
                         'parentRecordGroup | parentCollection', 'title')
    end

    # Use <contributorType>Most Recent</contributorType> if multiple
    # <contributor-display> values. 
    # Reject <contributorType>Publisher</contributorType>.
    #
    #  <organizationalContributorArray> OR <personalContributorArray>
    #    <organizationalContributor> OR <personalContributor>
    #      <contributor>
    #        <termName>[VALUE]</termName>
    #      </contributor>
    #      <contributorType>
    #        <termName>[VALUE]</termName>
    #      </contributorType>
    #    </organizationalContributor> OR </personalContributor>
    #  </organizationalContributorArray> OR </personalContributorArray>
    contributor :class => DPLA::MAP::Agent do
      providedLabel ""
    end

    # *Use <contributorType>Most Recent</contributorType> if multiple <contributor-display> values. 
    #
    # <creatingOrganizationArray> OR <creatingIndividualArray>
    #   <creatingOrganization> OR <creatingIndividual>
    #     <creator>
    #       <termName>[VALUE]</termName>
    #     </creator>
    #   </creatingOrganization> OR </creatingIndividual>
    # </creatingOrganizationArray> OR </creatingIndividualArray>
    creator :class => DPLA::MAP::Agent do
      providedLabel ""
    end

    # *Check for coverage dates first and if they are missing, then check for
    # other dates. These are ORs, not ANDs. Do not display all.
    # **NOT <hierarchy-item-inclusive-dates>
    #
    # <coverageDates>
    # <coverageEndDate>
    # <dateQualifier>[VALUE]</dateQualifier>
    # <day>[VALUE]</day>
    # <month>[VALUE]</month>
    # <year>[VALUE]</year>
    # </coverageEndDate>
    # <coverageStartDate>
    # <dateQualifier>[VALUE]</dateQualifier>
    # <day>[VALUE]</day>
    # <month>[VALUE]</month>
    # <year>[VALUE]</year>
    # </coverageStartDate>
    # </coverageDates>
    #
    # <copyrightDateArray>
    # <proposableQualifiableDate>
    # <dateQualifier>[VALUE]</dateQualifier>
    # <day>[VALUE]</day>
    # <month>[VALUE]</month>
    # <year>[VALUE]</year>
    # </proposableQualifiableDate>
    # </copyrightDateArray>
    #
    # <productionDateArray>
    # <proposableQualifiableDate>
    # <dateQualifier>[VALUE]</dateQualifier>
    # <day>[VALUE]</day>
    # <month>[VALUE]</month>
    # <year>[VALUE]</year>
    # </proposableQualifiableDate>
    # </productionDateArray>
    #
    # <broadcastDateArray>
    # <proposableQualifiableDate>
    # <dateQualifier/>[VALUE]</dateQualifier>
    # <day>[VALUE]</day>
    # <month>[VALUE]</month>
    # <year>[VALUE]</year>
    # <logicalDate>[VALUE]</logicalDate>
    # </proposableQualifiableDate>
    # </broadcastDateArray>
    #
    # <releaseDateArray>
    # <proposableQualifiableDate>
    # <dateQualifier>[VALUE]</dateQualifier>
    # <day>[VALUE]</day>
    # <month>[VALUE]</month>
    # <year>[VALUE]</year>
    # <logicalDate>[VALUE]</logicalDate>
    # </proposableQualifiableDate>
    # </releaseDateArray>
    date :class => DPLA::MAP::TimeSpan do
      providedLabel ""
      self.begin ""
      self.end ""
    end

    # <generalNoteArray>
    # <generalNote>
    # <note>[VALUE]</note>
    # </generalNote>
    # </generalNoteArray>
    #
    # <scopeAndContentNote>[VALUE]</scopeAndContentNote>
    description record.field('description', 'item | itemAv | fileUnit',
                             'scopeAndContentNote')

    # <extent>[VALUE]</extent>
    extent record.field('description', 'item | itemAv | fileUnit', 'extent')

    # <specificRecordsTypeArray>
    #  <specificRecordsType>
    #  <termName>[VALUE]</termName>
    # </specificRecordsType>
    # <specificRecordsTypeArray>"
    dcformat record.field('description', 'item | itemAv | fileUnit',
                          'specificRecordsTypeArray', 'specificRecordsType',
                          'termName')

    # <variantControlNumberArray>
    #  <variantControlNumber>
    #  <number>[VALUE1]</number>
    #  <type>
    #  <termName>[VALUE2]</termName>
    #  </type>
    #  </variantControlNumber>
    #  </variantControlNumberArray>
    # [combine as:  VALUE2: VALUE1
    identifier ""

    # <languageArray>
    # <language>
    # <termName>[VALUE]</termName>
    # </language>
    # </languageArray>
    language :class => DPLA::MAP::Controlled::Language do

      # FIXME:  shouldn't this be providedLabel?
      prefLabel record.field('description', 'item | itemAv | fileUnit',
                             'languageArray', 'language', 'termName')
    end

    # <geographicReferenceArray>
    #  <geographicPlaceName>
    #  <termName>[VALUE]</termName>
    #  </geographicPlaceName>
    # </geographicReferenceArray>
    spatial :class => DPLA::MAP::Place do
      providedLabel record.field('description', 'item | itemAv | fileUnit',
                                 'geographicReferenceArray',
                                 'geographicPlaceName', 'termName')
    end

    # **note these are contingent on the value of contributorType/termName
    # being ""Publisher""
    #
    # <organizationalContributorArray>
    #  <organizationalContributor>
    #  <contributor>
    #  <termName>[VALUE]</termName>
    #  </contributor>
    #  <contributorType>
    #  <termName>Publisher</termName>
    #  </contributorType>
    #  </organizationalContributor>
    #  </organizationalContributorArray>
    # 
    #  <personalContributorArray>
    #  <personalContributor>
    #  <contributor>
    #  <termName>[VALUE]</termName>
    #  </contributor>
    #  <contributorType>
    #  <termName>Publisher</termName>
    #  </contributorType>
    #  </personalContributor>
    #  </personalContributorArray>
    publisher :class => DPLA::MAP::Agent do
      providedLabel ""
    end

    # <parentFileUnit>
    #  <title>VALUE1</title>
    #  <parentSeries>
    #  <title>VALUE2</title>
    #  <parentRecordGroup>
    #  <title>VALUE3</title>
    #  </parentRecordGroup>
    #  </parentSeries>
    #  </parentFileUnit>
    #  [should be combed as VALUE3""; ""VALUE2""; ""VALUE1]
    #
    #  OR
    #
    #  <parentFileUnit>
    #  <title>VALUE1</title>
    #  <parentSeries>
    #  <title>VALUE2</title>
    #  <parentCollection>
    #  <title>VALUE3</title>
    #  </parentCollection>
    #  </parentSeries>
    #  </parentFileUnit>
    #  [should be combed as VALUE3""; ""VALUE2""; ""VALUE1]"
    relation ""

    # <useRestriction>
    # <note>VALUE1</note>
    # <specificUseRestrictionArray>
    # <specificUseRestriction>
    # <termName xmlns=""http://description.das.nara.gov/"">VALUE2</termName>
    # </specificUseRestriction>
    # </specificUseRestrictionArray>
    # <status>
    # <termName xmlns=""http://description.das.nara.gov/"">VALUE3</termName>
    # </status>
    # </useRestriction> [these should be combined as VALUE2"": ""VALUE1"" ""VALUE3]"
    rights record.field('description', 'item | itemAv | fileUnit',
                        'useRestriction', 'status', 'termName')

    # <topicalSubjectArray>
    # <topicalSubject>
    # <termName>[VALUE]</termName>
    # </topicalSubject>
    # </topicalSubjectArray>
    subject :class => DPLA::MAP::Concept do
      providedLabel record.field('description', 'item | itemAv | fileUnit',
                                 'topicalSubjectArray', 'topicalSubject',
                                 'termName')
    end

    title record.field('description', 'item | itemAv | fileUnit', 'title')

    # <generalRecordsTypeArray>
    #  <generalRecordsType>
    #  <termName>[VALUE]</termName>
    #  </generalRecordsType>
    #  </generalRecordsTypeArray>
    #
    # # to enrich:
    # Architectural and Engineering Drawings (image)
    # Artifacts (physical object)
    # Data Files (dataset)
    # Maps and Charts (image)
    # Moving Images (moving image)
    # Photographs and Other Graphic Materials (image)
    # Sound Recordings (sound)
    # Textual Records (text)
    # Web Pages (interactive resource)
    dctype record.field('description', 'item | itemAv | fileUnit',
                        'generalRecordsTypeArray', 'generalRecordsType',
                        'termName')
  end
end
