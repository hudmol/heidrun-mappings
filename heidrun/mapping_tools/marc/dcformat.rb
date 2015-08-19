module MappingTools
  module MARC
    ##
    # Methods that are used for assigning dc:format values
    #
    module DCFormat

      # Format given by control field 007, position 00,
      # per http://www.loc.gov/marc/bibliographic/bd007.html
      FORMAT_007_00 = {
        'a' => 'Map',
        'c' => 'Electronic resource',
        'd' => 'Globe',
        'f' => 'Tactile material',
        'g' => 'Projected graphic',
        'h' => 'Microform',
        'k' => 'Nonprojected graphic',
        'm' => 'Motion picture',
        'o' => 'Kit',
        'q' => 'Notated music',
        'r' => 'Remote-sensing image',
        's' => 'Sound recording',
        't' => 'Text',
        'v' => 'Videorecording',
        'z' => 'Unspecified'
      }

      # Format given by MARC leader, position 06,
      # per http://www.loc.gov/marc/bibliographic/bdleader.html
      LEADER_06 = {
        'a' => 'Language material',
        'c' => 'Notated music',
        'd' => 'Manuscript notated music',
        'e' => 'Cartographic material',
        'f' => 'Manuscript cartographic material',
        'g' => 'Projected medium',
        'i' => 'Nonmusical sound recording',
        'j' => 'Musical sound recording',
        'k' => 'Two-dimensional nonprojectable graphic',
        'm' => 'Computer file',
        'o' => 'Kit',
        'p' => 'Mixed materials',
        'r' => 'Three-dimensional artifact or naturally occurring object',
        't' => 'Manuscript language material'
      }

      module_function

      def assign_from_leader(formats, opts)
        formats << LEADER_06[opts[:leader][6]]  # nil if not found
      rescue NoMethodError
        raise NoElementError.new('No string for MARC leader')
      end

      def assign_from_cf007(formats, opts)
        formats << FORMAT_007_00[opts[:cf_007][0]]  # nil if not found
      rescue NoMethodError
        raise NoElementError.new('No string for control field 007')
      end
    end
  end
end