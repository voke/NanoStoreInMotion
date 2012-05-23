module NanoStore
  module FinderMethods    
    # find model by criteria
    #
    # Return array of models
    #
    # Examples:
    #   User.find(:name, NSFEqualTo, "Bob") # => [<User#1>]
    #   User.find(:name => "Bob") # => [<User#1>]
    #   User.find(:name => {NSFEqualTo => "Bob"}) # => [<User#1>]
    #
    def find(*arg)
      if arg[0].is_a?(Hash)
        # hash style
        options = arg[0]
        if arg[1] && arg[1].is_a?(Hash)
          sort_options = arg[1][:sort] || {}
        else
          sort_options = {}
        end
      elsif arg[0] && arg[1] && arg[2]
        # standard way to find
        options = {arg[0] => {arg[1] => arg[2]}}
        if arg[4] && arg[4].is_a?(Hash)
          sort_options = arg[4][:sort] || {}
        else
          sort_options = {}
        end
      else
        raise "unexpected parameters #{arg}"
      end
      search = NSFNanoSearch.searchWithStore(self.store)
      expressions = expressions_with_options(options)
      sort_descriptors = sort_descriptor_with_options(sort_options)
      search.expressions = expressions
      search.sort = sort_descriptors
      error_ptr = Pointer.new(:id)
      searchResults = search.searchObjectsWithReturnType(NSFReturnObjects, error:error_ptr)
      raise NanoStoreError, error_ptr[0].description if error_ptr[0]
      searchResults
    end
    
    # find model keys by criteria
    #
    # Return array of keys
    #
    # Examples:
    #   User.find(:name, NSFEqualTo, "Bob") # => [<User#1>]
    #   User.find(:name => "Bob") # => [<User#1>]
    #   User.find(:name => {NSFEqualTo => "Bob"}) # => [<User#1>]
    #
    def find_keys(*arg)
      if arg[0].is_a?(Hash)
        # hash style
        options = arg[0]
        if arg[1] && arg[1].is_a?(Hash)
          sort_options = arg[1][:sort] || {}
        else
          sort_options = {}
        end
      elsif arg[0] && arg[1] && arg[2]
        # standard way to find
        options = {arg[0] => {arg[1] => arg[2]}}        
        if arg[4] && arg[4].is_a?(Hash)
          sort_options = arg[4][:sort] || {}
        else
          sort_options = {}
        end
      else
        raise "unexpected parameters #{arg}"
      end
      search = NSFNanoSearch.searchWithStore(self.store)
      expressions = expressions_with_options(options)
      sort_descriptors = sort_descriptor_with_options(sort_options)
      search.expressions = expressions
      search.sort = sort_descriptors
      error_ptr = Pointer.new(:id)
      searchResults = search.searchObjectsWithReturnType(NSFReturnKeys, error:error_ptr)
      raise NanoStoreError, error_ptr[0].description if error_ptr[0]
      searchResults
    end
    
    protected
    def expressions_with_options(options)
      expressions = []
      options.each do |key, val|
        attribute = NSFNanoPredicate.predicateWithColumn(NSFAttributeColumn, matching:NSFEqualTo, value:key.to_s)
        expression = NSFNanoExpression.expressionWithPredicate(attribute)

        if val.is_a?(Hash)
          val.each do |operator, sub_val|
            value = NSFNanoPredicate.predicateWithColumn(NSFValueColumn, matching:operator, value:sub_val)
            expression.addPredicate(value, withOperator:NSFAnd)
          end
        else
          value = NSFNanoPredicate.predicateWithColumn(NSFValueColumn, matching:NSFEqualTo, value:val)
          expression.addPredicate(value, withOperator:NSFAnd)
        end
        expressions << expression
      end
      return expressions
    end
    
    SORT_MAPPING = {
      'ASC' => true,
      'DESC' => false,
      :ASC => true,
      :DESC => false
    }
    
    def sort_descriptor_with_options(options)
      sorter = options.collect do |opt_key, opt_val|
        if opt_val.is_a?(TrueClass) || opt_val.is_a?(FalseClass)
          NSFNanoSortDescriptor.alloc.initWithAttribute(opt_key.to_s, ascending:opt_val)
        elsif SORT_MAPPING.keys.include?(opt_val)
          NSFNanoSortDescriptor.alloc.initWithAttribute(opt_key.to_s, ascending:SORT_MAPPING[opt_val])
        else
          raise "unsupported sort parameters: #{opt_val}"
        end
      end
    end
  end # module FinderMethods
end # module NanoStore