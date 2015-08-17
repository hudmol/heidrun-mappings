module MappingTools
  module MARC
    ##
    # Methods that are used in assigning dctype values
    #
    module DCType

      module_function

      ##
      # Assign the value of datafield 337$a, if it exists.
      def assign_337a(types, opts)
        if opts.include?(:df_337a) && !opts[:df_337a].empty?
          types << opts[:df_337a]
        end
      end

      def assign_text(types, opts)
        if text?(opts[:leader])
          types << 'Text'
          true
        else
          false
        end
      end

      def assign_still_and_moving_image(types, opts)
        if still_or_moving_image?(opts[:leader])
          if film_video?(opts[:cf_007])
            types << 'Moving Image'
          else
            types << 'Image'
          end
          true
        else
          false
        end
      end

      def assign_sound(*args)
        if sound?(opts[:leader])
          types << 'Sound'
          true
        else
          false
        end
      end

      def assign_physical_object(*args)
        if physical_object?(opts[:leader])
          types << 'Physical Object'
          true
        else
          false
        end
      end

      def assign_collection(*args)
        if collection?(opts[:leader])
          types << 'Collection'
          true
        else
          false
        end
      end

      def assign_interactive_rsrc(*args)
        if interactive_rsrc?(opts[:leader])
          types << 'Interactive Resource'
          true
        else
          false
        end
      end

      def still_or_moving_image?(s)
        %w(e f g k).include?(s[6])
      end

      def text?(s)
        %w(a c d t).include?(s[6])
      end

      def sound?(s)
        %w(i j).include?(s[6])
      end

      def physical_object?(s)
        s[6] == 'r'
      end

      def collection?(s)
        ['p', 'o'].include?(s[6])
      end

      def interactive_rsrc?(s)
        s[6] == 'm'
      end
    end
  end
end
