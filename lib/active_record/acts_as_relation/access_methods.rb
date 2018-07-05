module ActiveRecord
  module ActsAsRelation
    module AccessMethods
      def define_acts_as_accessors(model_name)
        # The weird order of the if-else branches is so that we query ourselves
        # before we query our superclass.
        class_eval <<-EndCode, __FILE__, __LINE__ + 1
          def read_attribute(attr_name, *args, &proc)
            if attribute_method?(attr_name.to_s)
              super(attr_name, *args)
            else
              #{model_name}.read_attribute(attr_name, *args, &proc)
            end
          end

          def attributes
            if #{model_name}.changed? || changed?
              #{model_name}.attributes.to_hash.merge(super)
            elsif @attributes
              @attributes.to_hash
            else
              #{model_name}.attributes.to_hash.merge(super)
            end
          end

          def attributes=(new_attributes)
            sub = new_attributes.select { |k,v| attribute_method?(k) }
            sup = new_attributes.select { |k,v| !attribute_method?(k) }
            super(sub)
            #{model_name}.attributes = sup
          end

          def touch(name = nil, *args, &proc)
            if attribute_method?(name.to_s)
              super(name, *args, &proc)
            else
              super(nil, *args, &proc)
              #{model_name}.touch(name, *args, &proc)
            end
          end

          def save(*args)
            super(*args) && #{model_name}.save(*args)
          end

          def save!(*args)
            super(*args) && #{model_name}.save!(*args)
          end

          private

          def write_attribute(attr_name, *args, &proc)
            if attribute_method?(attr_name.to_s)
              super(attr_name, *args)
            else
              #{model_name}.send(:write_attribute, attr_name, *args, &proc)
            end
          end
        EndCode
      end

      def define_acts_as_reflectors(model_name, superclass_name)
        class_eval <<-EndCode, __FILE__, __LINE__ + 1
          def self.reflect_on_association(*args)
            self_value = super(*args)
            return self_value if self_value
            #{superclass_name}.reflect_on_association(*args)
          end

          def column_for_attribute(*args)
            self_column = super(*args)
            return self_column if self_column
            #{model_name}.column_for_attribute(*args)
          end
        EndCode
      end

      def define_acts_as_forwarders(acts_as)
        if acts_as.class_name.constantize.respond_to?(:enumerate)
          class_eval <<-EndCode, __FILE__, __LINE__ + 1
            def self.enumerated_attributes(*args)
              super_attr = #{acts_as.class_name}.enumerated_attributes
              super_attr ||= {}
              attr = super(*args)
              attr.merge!(super_attr) { |key, old, _| old } unless attr.nil?
            end

            def self.active_enum_for(*args)
              self_enum = super(*args)
              return self_enum if self_enum
              #{acts_as.class_name}.active_enum_for(*args)
            end
          EndCode
        end
      end

      protected :define_acts_as_accessors, :define_acts_as_reflectors,
        :define_acts_as_forwarders
    end
  end
end
