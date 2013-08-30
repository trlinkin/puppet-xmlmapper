module PuppetX; end
module PuppetX::Provider; end

class PuppetX::Provider::XmlComponent

  attr_reader :name

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
    check_input(:type, choice)
    unless [:attribute, :element].include? choice.intern
      raise Puppet::Error, "Component #{@name}: 'type' must be either :attribute or :element."
    end
    @type = choice.intern
  end

  def xml_name
    (@name_in_config || @name).to_s
  end

  def has_parent?
    !!@parent
  end

  def parent_name
    @parent
  end

  def is
    @type || :element
  end

  def is_type?(type)
    type = type.intern if type.respond_to? :intern and not type.is_a? Symbol
    type == is
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
