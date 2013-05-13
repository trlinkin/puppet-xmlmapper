module PuppetX
  module Provider; end
end

class PuppetX::Provider::XmlDeclComponent

  def initialize(&block)
    instance_eval &block if block_given?
  end

  def version(value)
    begin
      @version = Float(value)
    rescue
      raise Puppet::Error, "XML Version is not valid, cannot use \'#{value.to_s}\'"
    end

    if @version < 1
      raise Puppet::Error, 'XML Version must be \'1\' or greater'
    end
  end

  def encoding(value)
    @encoding = value
  end

  def standalone(value = 'yes')
    raise Puppet::Error, "XML stand-alone accepts either 'yes' or 'no', '#{value.to_s}' is not valid" unless [:yes,:no].include? value.to_sym
    @standalone = value
  end

  def [](name)
    name = name.intern if name.respond_to? :intern and not name.is_a? Symbol

    case name
    when :version
      @version || '1.0'
    when :encoding
      @encoding || 'UTF-8'
    when :standalone
      @standalone || 'no'
    end
  end
end
