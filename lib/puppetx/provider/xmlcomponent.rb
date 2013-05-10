module PuppetX; end
module PuppetX::Provider; end

class PuppetX::Provider::XmlComponent

  def initialize(name, &block)
    @name = name.intern
    instance_eval &block if block_given?
    validate
  end

  def method_missing(name, *args, &block)
    if [:parent, :name_in_config].include? name
      attr_assign(name, args.first.intern)
    else
      super(name, *args, &block)
    end
  end

  def type(choice)
    check_input :type, choice
    raise Puppet::Error, "Component #{@name}: 'type' must be either :attribute or :element." unless [:attribute, :element].include? choice.intern
    @type = choice.intern
  end

  def xml_name
    (@name_in_config || @name).to_s
  end

  def attr(name)
    return :element if name.intern == :type unless @type
    instance_variable_get("@#{name}")
  end

  def attr_assign(name, value)
    check_input name, value
    instance_variable_set("@#{name}", value.intern)
  end

  def check_input (name, value)
    raise Puppet::Error, "Component #{@name}: '#{name}' must be a string or symbol" unless value.is_a? String or value.is_a? Symbol
  end

  # Validation of component before we continue with more.
  def validate
  end
end
