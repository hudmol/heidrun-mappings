module MappingTools
  module MARC
    ##
    # Methods that are used in assigning genre values
    #
    module Genre

      module_function

      def assign_language(genres, opts)
        if language_material?(opts[:leader])
          if monograph?(opts[:leader])
            genres << 'Book'
          elsif serial?(opts[:leader])
            if newspapers?(opts[:cf_008])
              genres << 'Newspapers'
            else
              genres << 'Serial'
            end
          elsif mono_component_part?(opts[:leader])
            genres << 'Book'
          else
            genres << 'Serial'
          end
          true
        else
          false
        end
      end

      def assign_musical_score(genres, opts)
        if notated_music?(opts[:leader]) || manu_notated_music?(opts[:leader])
          genres << 'Musical Score'
          true
        else
          false
        end
      end

      def assign_manuscript(genres, opts)
        if manu_lang_material?(opts[:leader])
          genres << 'Manuscript'
          true
        else
          false
        end
      end

      def assign_maps(genres, opts)
        if cart_material?(opts[:leader]) || manu_cart_material?(opts[:leader])
          genres << 'Maps'
          true
        else
          false
        end
      end

      # projected media
      def assign_projected(genres, opts)
        if projected_medium?(opts[:leader])
          if slide?(opts[:cf_007]) || transparency?(opts[:cf_007])
            genres << 'Photograph / Pictorial Works'
            true
          elsif film_video?(opts[:cf_007])
            genres << 'Film / Video'
            true
          else
            false
          end
        else
          false
        end
      end

      # two-dimensional nonprojectable graphic
      def assign_two_d(genres, opts)
        if two_d_nonproj_graphic?(opts[:leader])
          genres << 'Photograph / Pictorial Works'
          true
        else
          false
        end
      end

      def assign_nonmusical_sound(genres, opts)
        if nonmusical_sound?(opts[:leader])
          genres << 'Nonmusic Audio'
          true
        else
          false
        end
      end

      def assign_musical_sound(genres, opts)
        if musical_sound?(opts[:leader])
          genres << 'Music'
          true
        else
          false
        end
      end

      ##
      # Whether the MARC leader indicates Language Material
      # @param s [String]  MARC leader
      def language_material?(s)
        s[6] == 'a'
      end

      ##
      # Whether the MARC leader indicates Monograph
      # @param s [String] MARC leader
      def monograph?(s)
        s[7] == 'm'
      end

      ##
      # Whether control field 008 indicates Newspapers
      # @param s [String] Control field 008
      def newspapers?(s)
        s[21] == 'n'
      end

      ##
      # Whether the MARC leader indicates Serial
      # @param s [String] MARC leader
      def serial?(s)
        s[7] == 's'
      end

      ##
      # Whether the MARC leader indicates a Monographic Component Part
      # @param s [String] MARC leader
      def mono_component_part?(s)
        s[7] == 'a'
      end

      ##
      # Whether the MARC leader indicates Notated Music
      # @param s [String] MARC leader
      def notated_music?(s)
        s[6] == 'c'
      end

      ##
      # Whether the MARC leader indicates Manuscript Notated Music
      # @param s [String] MARC leader
      def manu_notated_music?(s)
        s[6] == 'd'
      end

      ##
      # Whether the MARC leader indicates Manuscript Language Material
      # @param s [String] MARC leader
      def manu_lang_material?(s)
        s[6] == 't'
      end

      ##
      # Whether the MARC leader indicates Cartographic Material
      # @param s [String] MARC leader
      def cart_material?(s)
        s[6] == 'e'
      end

      ##
      # Whether the MARC leader indicates Manuscript Cartographic Material
      # @param s [String] MARC leader
      def manu_cart_material?(s)
        s[6] == 'f'
      end

      ##
      # Whether the MARC leader indicates Projected Medium
      # @param s [String] MARC leader
      def projected_medium?(s)
        s[6] == 'g'
      end

      ##
      # Whether Control Field 007 indicates Slide
      # @param s [String] Control Field 007
      def slide?(s)
        s[1] == 's'
      end

      ##
      # Whether Control Field 007 indicates Transparency
      # @param s [String] Control Field 007
      def transparency?(s)
        s[1] == 't'
      end

      ##
      # Whether the MARC leader indicates Two-Dimensional Non-Projectable
      # Graphic
      # @param s [String] MARC leader
      def two_d_nonproj_graphic?(s)
        s[6] == 'k'
      end

      ##
      # Whether the MARC leader indicates Nonmusical Sound Recording
      # @param s [String] MARC leader
      def nonmusical_sound?(s)
        s[6] == 'i'
      end

      ##
      # Whether the MARC leader indicates Musical Sound Recording
      # @param s [String] MARC leader
      def musical_sound?(s)
        s[6] == 'j'
      end

      ##
      # Whether Control Field 008 indicates Government Document
      # @param s [String] Control Field 008
      def government_document?(s)
        %w(a c f i l m o s).include?(s[28])
      end
    end
  end
end
