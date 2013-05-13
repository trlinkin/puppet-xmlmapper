require 'rexml/document'
require 'puppet/util/filetype'
require 'puppetx/provider/xmlcomponentstore'

# Forward Declaration
module PuppetX; end

module PuppetX::Provider; end

module PuppetX::Provider::XmlMapper

  def initialize(resource, element = nil)
    super resource

    if element.nil?
      @property_hash[:ensure] = :absent
    else
      @element = element
      @property_hash[:ensure] = :present
    end
  end

  def document_path
    @resource[self.class.document_path]
  end

  def create
    root_name = self.class.xpath.split("/").last
    @element = REXML::Element.new root_name

    # Singleton elements (such as root elements) have no sub-elements that establish
    # uniqueness. They are unique due to some external comparison
    # such as raw file path. Any elements that seems as though they
    # would have been a key should be controlled with a property if
    # the type is a unique_element.
    #
    unless self.class.singleton_element?

      # Support for composite namevars.
      #
      # Any namevar needs a corresponding component in the provider
      # in order to be created.
      resource.class.key_attribute_parameters.each do |key|
        namevar = key.name
        @property_hash[namevar] = @resource[namevar]
      end
    end

    @resource.class.validproperties.each do |property|
      if value = @resource.should(property)
        @property_hash[property] = value unless value == :absent
      end
    end

    # If everything is copacetic (the base element in the document we rely on) then
    # we should have no issue adding out new element to the document. If not, we fail
    # before we add a success to the report. If we succeed, the rest of the properties
    # and such will be added durring the flushing process.
    #
    # 'parent_path' is impliment whenever the resource we're managing is relative to another
    # element in the tree. It is an attempt to discover the correct base element in the tree.
    parent = nil
    if self.respond_to? :parent_path
      parent = parent_path
    end
    self.class.add_entity(@element, document_path, parent)

    @property_hash[:ensure] = :create
    dirty!
  end

  def destroy
    @property_hash[:ensure] = :absent

    # The element will remove itself from the document tree.
    @element.remove
  end


  # The ensure property gets checked first. This is when we want to see if we have a failure
  # with the file this particular intance is using. We have deferred the error until now because
  # we did not want to fail the prefetch for every instance using this metaclass. If any other Weblogic
  # config files are being managed, they should continue to process fine.
  #
  def exists?
    raise Puppet::Error, self.class.failed_message(document_path) if self.class.failed? document_path
    self.class.unref! document_path
    @property_hash[:ensure] and @property_hash[:ensure] == :present
  end

  def flush
    if self.dirty?
      @property_hash.keys.each do |key|
        apply_component key unless key == :ensure
      end
    end

    # if XSD parsing is successful, I will need to impliment the resequencing
    if resequence?
      resequence_element
    end


    self.class.flush_document document_path
  end

  # Update a component in the entity.
  def apply_component(component)
    unless component.is_a? PuppetX::Provider::XmlComponent
      name = component.intern
      component = self.class.component_store[name]
    else
      name = component.attr(:name)
    end

    path = self.class.component_store.xpath(component)
    match = REXML::XPath.first(@element, path)

    if @property_hash[name] == :absent
      unless match.nil?
        match.remove if [REXML::Element, REXML::Attribute].include? match.class
      end
    else
      if match.nil?
        match = create_component_in_entity(component)
      end

      unless @property_hash[name] == :present
        if match.is_a? REXML::Element
          match.text = @property_hash[name]
        elsif match.is_a? REXML::Attribute
          parent = match.element
          temp_attr = REXML::Attribute.new(name.to_s, @property_hash[name].to_s)

          # Replace the old attribute
          match.remove
          parent.add_attribute(temp_attr)
        end
      end
    end
  end

  def create_component_in_entity(component)
    name = component.xml_name
    type = component.attr(:type)

    if parent_name = component.attr(:parent)
      parent_component = self.class.component_store[parent_name.intern]
      path = self.class.component_store.xpath(parent_component)
      match = REXML::XPath.first(@element, path)

      unless match.nil?
        parent = match
      else
        parent = create_component_in_entity(parent_component)
      end
    else
      parent = @element
    end

    if type == :element
      new_component = REXML::Element.new name.to_s
      parent << new_component
    else
      new_component = REXML::Attribute.new name.to_s
      parent.add_attribute new_component
    end

    # If supported, the newly inserted element may need to bre re-arranged inside our entity.
    resequence!
    return new_component
  end

  def resequence_element

  end

  # Mark Local instance as dirty, create reference on document reference, document as dirty.
  def dirty!
    @dirty = true
    self.class.dirty! document_path
  end

  def dirty?
    @dirty
  end

  def resequence!
    @resequence = true
  end

  def resequence?
    @resequence
  end

  def self.included(klass)
    klass.extend PuppetX::Provider::XmlMapper::ClassMethods
    klass.mk_property_methods
    klass.initvars
  end

  module ClassMethods

    # Shared between all types using this mix-in
    @@documents = Hash.new {|h,k| h[k] = {}}

    # Multiple classes will need to operate on entities in one file.
    # This class variable lets us keep everything in order.
    #
    def documents
      @@documents
    end

    attr_accessor :xpath
    attr_accessor :document_path
    attr_reader   :instances
    attr_reader   :component_store

    # Relevant to only Meta-Classes of the types implimenting this mix-in.
    # Since each type can modify multiple domains, the meta-classes need a way
    # to keep track of the instances
    #
    # Called upon including the XmlMapper module in a provider.
    #
    def initvars
      @instances       = Hash.new {|h,k| h[k] = []}
      @xpath           = String.new
      @document_path   = 'document_path'
      @component_store = PuppetX::Provider::XmlComponentStore.new
    end

    # Create methods for getting current value and setting desired value of components in the
    # provider
    #
    def mk_property_methods
      resource_type.validproperties.each do |attr|
        attr = attr.intern if attr.respond_to? :intern and not attr.is_a? Symbol

        next if :ensure == attr

        define_method(attr) do
          component = self.class.component_store[attr]
          path = self.class.component_store.xpath(component)
          property = REXML::XPath.first(@element, path)

          return :present if property and resource.should(attr) == :present

          if property.is_a? REXML::Element and property.has_text?
            return property.text
          elsif property.is_a? REXML::Attribute
            return property.value
          end

          return :absent
        end

        define_method("#{attr}=") do |val|
          @property_hash[attr] = val
          self.dirty!
        end
      end
    end

    # Called by puppet to prefetch resources from the disk.
    #
    def prefetch(resources = {})
      resources.each do |name, resource|
        doc = resource[self.document_path]
        fetch_document( doc )

        fetch_instances( doc )

        match_resource_with_provider( resource, doc )
      end
    end

    # Attempts to open a file as a Puppet::Util::FileType, parse it into an XML document object
    # using REXML, and cache both the results.
    #
    # If the file does not exist, it will be created.
    #
    def fetch_document(document)
      if !fetched_document? document then
        file = Puppet::Util::FileType.filetype(:flat).new(document)

        begin
          xml_doc = REXML::Document.new file.read
        rescue Puppet::Error => detail
          failed!(document, detail.message)
        rescue REXML::ParseException => detail
          msg = detail.continued_exception.to_s.split("\n")[0]
          failed!(document, "Failed to open #{document}: #{msg}")
        end

        mapped_file(document, file)
        xml_document(document, xml_doc)
      end
    end

    # Check to see if the file path being referenced has already been processed with `fetch_document`.
    #
    # @return [TrueClass || FalseClass]
    def fetched_document?(document)
      documents.has_key? document
    end

    def fetch_instances(document)
      raise Puppet::Error, "XmlMapper based provider \"#{name}\" needs to have a search xpath set." if xpath.empty?

      unless failed? document and !fetched_instances? document
        xml = xml_document document
        instances[document] = REXML::XPath.match xml, xpath
      end
    end

    def fetched_instances?(document)
      instances.has_key? document
    end

    def match_resource_with_provider(resource, document)
      unless failed? document
        ref! document
        matches = instances[document]
        keys    = resource.class.key_attribute_parameters

        matches.each do |match|
          matched = true

          # Rexml Should only ever load one root or singleton element. By that reasoning,
          # it is an automatic match. This means though, that for a type
          # representing a singleton or root element, it needs to have some other sorce of
          # uniqueness in the catalog. The most reasonable form of uniqueness
          # is the raw document path.
          #
          # Rexml will throw an excpetion if it were to ever attempt to load two
          # root_elements. It will also not write two root elements to the raw file.
          # Such an action as writing two root_elements to the raw file would cause
          # every type manipulating that file to not persist. I'm not sure of a good
          # way to have those errors bubble back up to the inidividual types since they
          # will technically think they have completed before the raw file flush is
          # performed.
          #
          unless singleton_element?
            keys.each do |key|
              value = resource[key.name].intern
              component = component_store[key.name]
              xpath = component_store.xpath(component)
              element = REXML::XPath.match(match, xpath).first

              if element.is_a? REXML::Element
                element_value = element.text.intern
              elsif element.is_a? REXML::Attribute
                element_value = element.value.intern
              end

              if element.nil? or value != element_value
                matched = false
                break
              end
            end
          end

          if matched
            provider = new(resource, match)
            resource.provider = provider
            matches.delete(match)
            return
          end
        end

        # We could not find a match, so we are going with a default provider.
        provider = new(resource)
        resource.provider = provider
      end
    end

    def add_xmldecl(document, decl)
      doc = xml_document(document)
      if doc.xml_decl.document.nil?
        doc << decl
      else
        doc.xml_decl.replace_with decl
      end
    end

    def remove_xmldecl(document)
      doc = xml_document(document)
      doc.xml_decl.remove
    end

    def add_entity(element, document, path = nil)
      unless path
        path = xpath.split('/')
        path.pop
        path = path.join('/')
      end

      doc = xml_document(document)
      parent = REXML::XPath.first(doc, path)

      raise Puppet::Error, "Cannot save resource, parent element \"#{path}\" not found." if parent.nil?
      parent << element
    end

    def flush_document(document)
      unless ref?(document)
        contents = String.new
        file = mapped_file(document)
        xml_doc = xml_document(document)
        formatter = REXML::Formatters::Pretty.new
        formatter.compact = true
        formatter.write(xml_doc, contents)
        file.backup
        file.write(contents)
      end
    end

    # Mark document as failed, and optionally provide a reason. If called again
    # it could overwrite the message, however, you should not be doing things
    # that could put you in a failure state if you're already failed.
    def failed!(document, msg = nil)
      documents[document][:failure_message] = msg
      documents[document][:failed] = true
    end

    def failed?(document)
      documents[document][:failed]
    end

    def failed_message(document)
      return "There is a failure with the WebLogic config." unless documents[document][:failure_message]
      documents[document][:failure_message]
    end

    def mapped_file(document, file = nil)
      return documents[document][:filetype] unless file and not failed? document
      documents[document][:filetype] = file
      documents[document][:dirty] = false
      documents[document][:ref]   = 0
    end

    def xml_document(document, xml = nil)
      return documents[document][:xml] unless  xml and documents[document][:xml].nil?
      documents[document][:xml] = xml
    end

    def dirty!(document)
      documents[document][:dirty] = true
    end

    def dirty?(document)
      documents[document][:dirty]
    end

    def ref!(document)
      documents[document][:ref] += 1
    end

    def unref!(document)
      documents[document][:ref] -= 1
    end

    def ref?(document)
      documents[document][:ref] > 0
    end

    # Root elements are globally unique and have access to the xmldecl and doctype
    def root_element
      @root_element = true
      singleton_element
    end

    def root_element?
      @root_element
    end

    # Are we globally unique?
    def singleton_element
      @singleton = true
    end

    def singleton_element?
      @singleton
    end

    def new_component(name, &block)
      component_store.new_component(name, &block)
    end

    # Add an XML declaration to types that are root elements. Right now, we only allow one to specify
    # the contents of the xmldecl entity and control its existence. If different versions of documents need
    # to be managed by a type, it propbably is due to the version of the software being used. Thus, the declaration
    # version itself is not an appropriate thing to manage. One alternative could be using one 'xmldecl' call over
    # another based on the value of a parameter representing software version. This would be slightly more coherent.
    #
    # This declaration does need a propety to manage it. A simple property with a default will work just fine. There
    # really is not a simpler way to manage this individual peice of the xml document than the property mechanisms.
    #
    # TODO: Right now, this code is very heavy in REXML. Eventually, it will use a future 'xmlhelper' class to build
    # and compare declarations. The intention being that xmlmapper will eventually support nokogiri.
    #
    # TODO: As part of the xml_document abstraction layer, I need to account for REXML's broken processing of the
    # REXML::XMLDecl's "standalone" attribute in Ruby 1.8.7 (sigh). For now I'll leave it commented out.
    #
    def xmldecl(name = :xmldecl, &block)
      fail("Cannot add an XML Declaration, this entity is not a Root Element") unless root_element?
      fail("Cannot add a second XML Declaration") if xmldecl?

      @xmldecl = true
      # Taking advantage of the closure to reference the declaration
      xmldecl = PuppetX::Provider::XmlDeclComponent.new(&block)

      name = name.intern if name.respond_to? :intern and not name.is_a? Symbol

      define_method(name) do
        doc = self.class.xml_document(document_path)
        return :absent if doc.xml_decl.document.nil?
        return :present if resource[name] == :absent

        # if the property is set to :present, we want to compare our built xmldecl to the xml document's
        decl = REXML::XMLDecl.new
        decl.version    = xmldecl[:version]
        decl.encoding   = xmldecl[:encoding]
        #decl.standalone = xmldecl[:standalone]

        old_decl = doc.xml_decl

        return :present if decl.to_s == old_decl.to_s
        :absent
      end

      define_method("#{name}=") do |val|
        if val == :absent
          self.class.remove_xmldecl(document_path)
          dirty!
        else
          decl = REXML::XMLDecl.new
          decl.version    = xmldecl[:version]
          decl.encoding   = xmldecl[:encoding]
          #decl.standalone = xmldecl[:standalone]

          self.class.add_xmldecl(document_path, decl)
          dirty!
        end
      end
    end

    def xmldecl?
      @xmldecl
    end
  end
end
