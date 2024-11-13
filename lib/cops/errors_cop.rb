module Cops
  # Ensures custom exceptions follow the correct pattern
  class ErrorsCop < RuboCop::Cop::Base
    def on_class(node)
      class_name, superclass, body = *node

      return if body.nil?

      # Check if the superclass is StandardError
      return unless superclass&.const_name == 'StandardError'

      # Check if the class name ends with "Error"
      unless class_name.const_name.end_with?('Error')
        add_offense(class_name, message: 'Class name should end with "Error".')
      end

      # Ensure `initialize` is present
      initialize_method_node = body.children.find { |child| initialize_method_node?(child) }
      if initialize_method_node
        check_initialize_method(initialize_method_node)
        check_attr_readers(body, initialize_method_node)
      end
    end

    private

      def initialize_method_node?(node)
        node.def_type? && node.method?(:initialize)
      end

      def check_initialize_method(node)
        args = node.arguments
        assigned_instance_vars = []
        children = node.body&.children || []

        children.each do |child|
          # Collect all instance variable assignments
          if child.ivasgn_type?
            var_name = child.children.first
            assigned_instance_vars << var_name

            # Check that no instance variable is named @message
            add_offense(child, message: 'Instance variable @message is not allowed.') if var_name == :@message
          end

          # Check that super is called after all instance variables are assigned
          if super_call?(child)
            unassigned_vars = args.map { |arg| :"@#{arg.children.first}" } - [:@message] - assigned_instance_vars
            unless unassigned_vars.empty?
              add_offense(child, message: 'super should be called after all instance variables are assigned.')
            end
          end
        end

        args.each do |arg|
          var_assignment = children.any? do |child|
            child.ivasgn_type? && (child.children.first == :"@#{arg.children.first}" || arg.children.first == :message)
          end

          unless var_assignment
            add_offense(arg, message: "Instance variable @#{arg.children.first} is not assigned.")
          end
        end

        # Check for any call to super, regardless of arguments
        unless children.any? { |child| super_call?(child) }
          add_offense(node, message: 'Missing super call.')
        end
      end

      def super_call?(node)
        node.keyword? && node.method?(:super)
      end

      def check_attr_readers(body, initialize_method_node)
        # Collect all instance variables assigned in initialize
        assigned_instance_vars = initialize_method_node.each_descendant(:ivasgn).map do |ivasgn_node|
          ivasgn_node.children.first
        end

        # Collect all declared attr_reader symbols
        attr_reader_nodes = body.each_descendant(:send).select do |send_node|
          send_node.method?(:attr_reader)
        end

        declared_attr_readers = attr_reader_nodes.flat_map do |attr_reader_node|
          attr_reader_node.arguments.map(&:value)
        end

        # Check that each assigned instance variable has a corresponding attr_reader
        assigned_instance_vars.each do |var|
          unless declared_attr_readers.include?(var.to_s[1..].to_sym)
            add_offense(body, message: "Instance variable #{var} is not accessible via attr_reader.")
          end
        end
      end
  end
end
