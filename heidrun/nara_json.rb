def nara_catalog_uri(id)
  "http://catalog.archives.gov/id/#{id.node}"
end

# Return a string for sourceResource.relation
#
# <parentFileUnit>
#  <title>VALUE1</title>
#  <parentSeries>
#    <title>VALUE2</title>
#    <parentRecordGroup>
#      <title>VALUE3</title>
#    </parentRecordGroup>
#  </parentSeries>
#  </parentFileUnit>
#  [should be combed as VALUE3""; ""VALUE2""; ""VALUE1]
#
#  OR
#
#  <parentFileUnit>
#  <title>VALUE1</title>
#  <parentSeries>
#    <title>VALUE2</title>
#    <parentCollection>
#      <title>VALUE3</title>
#    </parentCollection>
#  </parentSeries>
#  </parentFileUnit>
#  [should be combed as VALUE3""; ""VALUE2""; ""VALUE1]"
#
# @param parent_file_unit [Krikri::JsonParser::Value]
# @return [String]
#
# @todo: why are we semicolon delimiting these, won't we just split them later?
def make_relation(parent_file_unit)
  title = parent_file_unit['title']
  ps = parent_file_unit['parentSeries']
  parent_srs_title = ps.field('title')
  group_coll_title = ps.field('parentRecordGroup | parentCollection', 'title')
  "#{group_coll_title.first.value}; #{parent_srs_title.first.value}; " \
  "#{title.first.value}"
end

# <useRestriction>
#   <note>VALUE1</note>
#   <specificUseRestrictionArray>
#     <specificUseRestriction>
#       <termName xmlns=""http://description.das.nara.gov/"">VALUE2</termName>
#     </specificUseRestriction>
#   </specificUseRestrictionArray>
#   <status>
#     <termName xmlns=""http://description.das.nara.gov/"">VALUE3</termName>
#   </status>
# </useRestriction>
#
# These should be combined as "VALUE2: VALUE1 VALUE3"
#
# @param element [Krikri::JsonParser::Value]
# @return [String]
def make_rights(use_restriction)
  node = use_restriction.node
  note = node.fetch('note', nil)
  sura = node.fetch('specificUseRestrictionArray', nil)
  status = node.fetch('status', nil)
  l_and_r_parts = \
    [specific_rights_part(sura), genl_rights_part(note, status)].compact
  l_and_r_parts.join ': '
end

# @see #make_rights
def specific_rights_part(specific_use_restriction_array)
  return nil if specific_use_restriction_array.nil?
  sur = specific_use_restriction_array['specificUseRestriction']
  sur = [sur] unless sur.is_a? Array
  terms = sur.map { |el| el['termName'] }
  terms.join ', '
end

# @see #make_rights
def genl_rights_part(note, status)
  [note, status['termName']].compact.join ' '
end

# @see #make_begin_date
# @see #make_end_date
#
# @param node [Hash]
# @return [String]
#
# @todo: refactor to accept a ValueArray and handle the empty case
def date_string(node)
  return "" if node.nil?
  ymd = [
    node.fetch('year', nil), node.fetch('month', nil), node.fetch('day', nil)
  ].compact.map { |e| "%02d" % e }.join '-'
  qualifier_node = node.fetch('dateQualifier', false)

  return ymd unless qualifier_node

  qualifier = qualifier_node['termName']
  (qualifier == '?') ? "#{ymd}#{qualifier}" : "#{qualifier} #{ymd}"
end

# Date and temporal fields
#
# FIXME:
#
# This may be wrong.  The original comment in this file was:
#
# <quote>
#   *Check for coverage dates first and if they are missing, then check for
#   other dates. These are ORs, not ANDs. Do not display all.
#   **NOT <hierarchy-item-inclusive-dates>
# </quote>
#
# ... But it looks to me like coverageDates is supposed to represent
# "aboutness" as dcterms:temporal, and the other ones are supposed to represent
# a publication, production, or copyright date as dc:date.
#
# This needs verification.
#
# <coverageDates>
#   <coverageEndDate>
#     <dateQualifier>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#   </coverageEndDate>
#   <coverageStartDate>
#     <dateQualifier>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#   </coverageStartDate>
# </coverageDates>
#
# <copyrightDateArray>
#   <proposableQualifiableDate>
#     <dateQualifier>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#   </proposableQualifiableDate>
# </copyrightDateArray>
#
# <productionDateArray>
#   <proposableQualifiableDate>
#     <dateQualifier>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#   </proposableQualifiableDate>
# </productionDateArray>
#
# <broadcastDateArray>
#   <proposableQualifiableDate>
#     <dateQualifier/>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#     <logicalDate>[VALUE]</logicalDate>
#   </proposableQualifiableDate>
# </broadcastDateArray>
#
# <releaseDateArray>
#   <proposableQualifiableDate>
#     <dateQualifier>[VALUE]</dateQualifier>
#     <day>[VALUE]</day>
#     <month>[VALUE]</month>
#     <year>[VALUE]</year>
#     <logicalDate>[VALUE]</logicalDate>
#   </proposableQualifiableDate>
# </releaseDateArray>
#
# A record can have both dc:date and dcterms:temporal values, like
# coverageDates and broadcastDateArray in
# https://catalog.archives.gov/api/v1?pretty=true&resultTypes=item%2CfileUnit&objects.object.@objectSortNum=1&naIds=5860128

Krikri::Mapper.define(:nara_json, :parser => Krikri::JsonParser) do
  provider :class => DPLA::MAP::Agent do
    uri 'http://dp.la/api/contributor/nara'
    label 'National Archives and Records Administration'
  end

  dataProvider :class => DPLA::MAP::Agent, 
               :each => record.field('description', 'item | itemAv | fileUnit',
                                     'physicalOccurrenceArray',
                                     'itemPhysicalOccurrence |' \
                                     'itemAvPhysicalOccurrence |' \
                                     'fileUnitPhysicalOccurrence',
                                     'referenceUnitArray', 'referenceUnit',
                                     'name'),
               :as => :agent do
    providedLabel agent
  end

  isShownAt :class => DPLA::MAP::WebResource do
    uri record.field('naId').first_value.map { |id| nara_catalog_uri(id) }
  end

  object :class => DPLA::MAP::WebResource,
         :each => record.field('objects', 'object', 'file')
                 .select { |file| file.child?('@url') }.first_value,
         :as => :file_obj do
    uri file_obj.field('@url').first_value.map { |url| URI.escape(url.value) }
    dcformat file_obj.field('@mime').first_value
  end

  preview :class => DPLA::MAP::WebResource,
         :each => record.field('objects', 'object', 'thumbnail').first_value
                 .select { |file| file.child?('@url') },
         :as => :file_obj do
    uri file_obj.field('@url').first_value.map { |url| URI.escape(url.value) }
    dcformat file_obj.field('@mime').first_value
  end

  originalRecord :class => DPLA::MAP::WebResource do
    uri record_uri
  end

  sourceResource :class => DPLA::MAP::SourceResource do
    # <parentRecordGroup> OR <parentCollection>
    #   <naId>[VALUE]</naId>
    #   <title>[VALUE]</title>
    #   <recordGroupNumber>[VALUE]</recordGroupNumber>
    # </parentRecordGroup> OR </parentCollection>
    #
    # @todo: some of the NARA records have what look like collections
    #   nested under a `parentFileUnit`. do we need to catch these?
    collection :class => DPLA::MAP::Collection,
               :each => record.field('description', 'item | itemAv | fileUnit',
                                     'parentSeries',
                                     'parentRecordGroup | parentCollection', 'title'),
               :as => :collection_title do
      title collection_title
    end

    # @todo: mapping spreadsheet says to use 'Most Recent' if multiple 
    #   <contributor-display> values are present. It's not clear what this 
    #   means in the JSON context.
    contributor :class => DPLA::MAP::Agent,
                :each => record.field('description', 'item | itemAv | fileUnit',
                                      'organizationalContributorArray | ' \
                                      'personalContributorArray',
                                      'organizationalContributor | ' \
                                      'personalContributor')
                        .reject { |c| c['contributorType'].field('termName')
                                  .values.include?('Publisher') }
                        .field('contributor'),
                :as => :contributor do
      providedLabel contributor.field('termName')
    end

    # *Use <contributorType>Most Recent</contributorType> if multiple <contributor-display> values.
    #
    # FIXME:  the instruction on the line above doesn't make sense with the
    #         structure of this element in the original data. Verify?
    #
    # <creatingOrganizationArray> OR <creatingIndividualArray>
    #   <creatingOrganization> OR <creatingIndividual>
    #     <creator>
    #       <termName>[VALUE]</termName>
    #     </creator>
    #   </creatingOrganization> OR </creatingIndividual>
    # </creatingOrganizationArray> OR </creatingIndividualArray>
    creator :class => DPLA::MAP::Agent,
            :each => record.field('description', 'item | itemAv | fileUnit',
                                  'parentSeries',
                                  'creatingOrganizationArray |' \
                                  'creatingIndividualArray',
                                  'creatingOrganization | creatingIndividual',
                                  'creator', 'termName'),
            :as => :creator_name do
      providedLabel creator_name
    end

    # @todo: `coverageDates` should be included here, but they often return 
    #   without *any* values (`nil` begin & end dates), making them hard to 
    #   skip over
    #
    # @todo: add mapping for begin/end on coverageDates.
    date :class => DPLA::MAP::TimeSpan,
         :each => record.field('description', 'item | itemAv | fileUnit',
                               'copyrightDateArray |' \
                               'productionDateArray | broadcastDateArray |' \
                               'releaseDateArray', 'proposableQualifiableDate'),
         :as => :dates do
      providedLabel dates.map { |d| date_string(d.node) }
      # self.begin dates.field('coverageStartDate').map { |d| date_string(d.node) }
      # self.end dates.field('coverageEndDate').map { |d| date_string(d.node) }
    end

    # This has no mapping, according to the 4.0 spreadsheet, `coverageDates`
    # should be be in dc:date
    # temporal :class => DPLA::MAP::TimeSpan,
    #          :each => record.field('description', 'item | itemAv | fileUnit',
    #                                'coverageDates'),
    #          :as => :dates do
    #   # providedLabel dates.map { |d| make_date_provided_label(d) }
    #   self.begin dates.map { |d| make_begin_date(d) }
    #   self.end dates.map { |d| make_end_date(d) }
    # end

    description record.field('description', 'item | itemAv | fileUnit',
                             'scopeAndContentNote | generalNoteArray',
                             'generalNote', 'note')

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

    identifier record.field('description', 'item | itemAv | fileUnit',
                            'variantControlNumberArray',
                            'variantControlNumber')
                .map { |vcn| result = [vcn['type'].field('termName').values.first,
                                       vcn['number'].values.first].compact.join(': ') }

    # <languageArray>
    # <language>
    # <termName>[VALUE]</termName>
    # </language>
    # </languageArray>
    language :class => DPLA::MAP::Controlled::Language,
             :each => record.field('description', 'item | itemAv | fileUnit',
                                   'languageArray', 'language', 'termName'),
             :as => :lang do
      providedLabel lang
    end

    # <geographicReferenceArray>
    #  <geographicPlaceName>
    #  <termName>[VALUE]</termName>
    #  </geographicPlaceName>
    # </geohgraphicReferenceArray>
    spatial :class => DPLA::MAP::Place, 
            :each => record.field('description', 'item | itemAv | fileUnit',
                                  'geographicReferenceArray',
                                  'geographicPlaceName', 'termName'),
            :as => :place do
    
      providedLabel place
    end

    publisher :class => DPLA::MAP::Agent,
              :each => record.field('description', 'item | itemAv | fileUnit',
                                    'organizationalContributorArray | ' \
                                    'personalContributorArray',
                                    'organizationalContributor | ' \
                                    'personalContributor')
                      .select { |c| c['contributorType'].field('termName')
                                .values.include?('Publisher') }
                      .field('contributor'),
              :as => :agent do
      providedLabel agent.field('termName')
    end

    relation record.field('description', 'item | itemAv | fileUnit',
                          'parentFileUnit')
                   .map { |parent| make_relation(parent) }

    rights record.field('description', 'item | itemAv | fileUnit',
                        'useRestriction')
                 .map { |el| make_rights(el) }

    # <topicalSubjectArray>
    # <topicalSubject>
    # <termName>[VALUE]</termName>
    # </topicalSubject>
    # </topicalSubjectArray>
    subject :class => DPLA::MAP::Concept,
            :each => record.field('description', 'item | itemAv | fileUnit',
                                  'topicalSubjectArray', 'topicalSubject',
                                  'termName'),
            :as => :concept do
      providedLabel concept
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
