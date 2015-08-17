module MappingTools
  ##
  # Static methods for evaluations and assignments that can be shared between
  # mappings of MARC providers.
  #
  module MARC
    require_relative 'marc/genre'
    require_relative 'marc/dctype'

    # Lambdas for `.select` calls performed on record nodes (which are
    # Krikri::XmlParser::Value objects)
    #
    # @example:
    #   cf_007 = r.node.children
    #             .select(&MappingTools::MARC::IS_CF7_NODE)
    #             .first.children.to_s
    #
    IS_LEADER_NODE = lambda { |node| node.name == 'leader' }
    IS_CF7_NODE = lambda { |node|
      node.name == 'controlfield' && node[:tag] == '007'
    }
    IS_CF8_NODE = lambda { |node|
      node.name == 'controlfield' && node[:tag] == '008'
    }
    IS_DF337_NODE = lambda { |node|
      node.name == 'datafield' && node[:tag] == '337'
    }
    IS_SF_A = lambda { |element|
      element.name == 'subfield' && element[:code] == 'a'
    }

    module_function

    ##
    # Given options representing leader and controlfield values, return an
    # array of applicable genre (edm:hasType) controlled-vocabulary terms
    #
    # Options are as follows, and are all Strings:
    #   - leader:  value of MARC 'leader' element
    #   - cf_007:  value of MARC 'controlfield' with 'tag' attribute '007'
    #   - cf_008:  value of MARC 'controlfield' with 'tag' attribute '008'
    #   - cf_970a:  TODO
    #
    # @param opts [Hash] Options, as outlined above
    # @return [Array]
    def genre(opts)
      genres = []
      args = [genres, opts]
      # TODO: insert handling of optional cf_970a for Hathi, as the first
      # evaluation.
      Genre.assign_language(*args) || Genre.assign_musical_score(*args) \
        || Genre.assign_manuscript(*args) || Genre.assign_maps(*args) \
        || Genre.assign_projected(*args) || Genre.assign_two_d(*args) \
        || Genre.assign_nonmusical_sound(*args) \
        || Genre.assign_musical_sound(*args)
      genres << 'Government Document' if Genre.government_document?(opts[:cf_008])
      genres
    end

    def dctype(opts)
      types = []
      args = [types, opts]
      DCType.assign_337a(*args)
      DCType.assign_text(*args) \
        || DCType.assign_still_and_moving_image(*args) \
        || DCType.assign_sound(*args) || DCType.assign_physical_object(*args) \
        || DCType.assign_collection(*args) \
        || DCType.assign_interactive_rsrc(*args)
      types
    end

    ##
    # Whether Control Field 007 indicates Film / Video
    # @param s [String] Control Field 007
    def film_video?(s)
      %w(c d f o).include?(s[1])
    end
  end
end
