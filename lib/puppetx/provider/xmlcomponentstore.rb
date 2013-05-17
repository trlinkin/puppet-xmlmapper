require 'puppetx/provider/xmlcomponent'

module PuppetX; end
module PuppetX::Provider; end

class PuppetX::Provider::XmlComponentStore

  def new_component(name, &block)
    name = name.intern
    if block_given?
      components[name] = PuppetX::Provider::XmlComponent.new(name, &block)
    else
      components[name] = PuppetX::Provider::XmlComponent.new(name) do
        type :element
      end
    end
  end

  def [](name)
    name = name.intern
    raise Puppet::Error, "No component \"#{name}\" available" unless components.include? name
    components[name]
  end

  def xpath(component)
    name = component.name
    xml_name = component.xml_name
    # If we have it cached, return it.
    cached = xpath_cache[name]
    return cached unless cached.nil?

    parent_path = "."
    if parent = component.parent_name
      begin
        parent_path = self.xpath(self[parent])
      rescue Puppet::Error => e
        raise Puppet::Error, "Component \"#{name}\" cannot find its parent \"#{parent}\""
      end
    end

    if component.is_type? :attribute
      xml_name = "@#{xml_name}"
    end
    path = "#{parent_path}/#{xml_name}"
    xpath_cache[name] = path
    return path
  end

  private

  def components
    @component ||= {}
  end

  def xpath_cache
    @xpath_cache ||= {}
  end

end
