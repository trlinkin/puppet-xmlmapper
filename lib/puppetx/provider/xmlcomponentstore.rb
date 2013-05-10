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
    name = component.attr(:name_in_config) ? component.attr(:name_in_config) : component.attr(:name)

    # If we have it cached, return it.
    cached = xpath_cache[name]
    return cached unless cached.nil?

    parent_path = "."
    if parent = component.attr(:parent)
      begin
        parent_path = self.xpath(self[parent.intern])
      rescue Puppet::Error => e
        raise Puppet::Error, "Component \"#{component.attr(:name)}\" cannot find its parent \"#{component.attr(:parent)}\""
      end
    end

    if component.attr(:type) == :attribute
      name = "@#{name}"
    end
    path = "#{parent_path}/#{name}"
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
