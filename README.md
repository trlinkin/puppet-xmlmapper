puppet-xmlmapper
----------------
[![Code Climate](https://codeclimate.com/github/trlinkin/puppet-xmlmapper.png)](https://codeclimate.com/github/trlinkin/puppet-xmlmapper)

XmlMapper makes creating providers to control XML configuration a breeze!

## Overview

XmlMapper is a mixin that allows different portions of an XML document to be expressed easily in a Puppet resource 
provider. It works in a manner very similar to the property/parameter concepts used in a Puppet resource type. The challenges
of controlling the XML elements and attributes comes down to a few simple function calls.

#### Why?
XML documents can get complicated, easily. I'll leave it at "there is more than one good reason people like yaml/json these
days." This is all compounded by the fact that it seems not everyone uses XML the same way. Like most things, XML can be poorly
used and made to be very convoluted. Lastly, since it still has a sort of affiliation with "Enterprise Products" and
especially Java, it's not going away any time soon.

That being the case, managing XML in Puppet can be tricky, and not as declarative as it should be. There are some
approaches using fragments and concatenation, and while good for most other types of configuration (easily applicable to ini
style files), limits and irritation are quickly faced when tying to apply such ideas to XML.

Usage
-----

## Basic API

### `Puppet::Type`

#### `document_path`

Any type using XmlMapper in the provider needs to impliment a `document_path` instance method. This is
used by the provider to load and parse the file being manipulated. This method must return a fully
qualified file path.

### `Puppet::Provider`

#### `self.xpath=(xpath)`

This method is used to set a static Xpath that the provider should use to find instances. This method sets the
class instance variable `@xpath`.

#### `self.xpath`

This method should return an Xpath as a string. This method is used internally by the XmlMapper. By default it
returns the value of the `@xpath` class instance variable. It may be reimplimented to provide an Xpath from a
more advanced source. Examples are Xpaths that are relative to a parameter. TODO: Provide example.

#### `self.root_element`

This method can be called to indicate that XML Element we're mapping is an XML root element. XML root elements have
access to the `xmldecl` and `doctype` methods. An XML root element is essentially a singleton element, as in there
can only be one per XML file. As such, the type needs to have a `namevar` that is not tied to an XmlMapper "componenet".

#### `self.singleton_element`

#### `self.xmldecl (type_property_mapping)`

#### `self.doctype(type_property_mapping)`

#### `self.new_component(type_property_mapping, block)`

### `self.new_component` context

#### `type`

#### `parent`

#### `name_in_config`
Author
------

Thomas Linkin <trlinkin@gmail.com>

License
-------

    Author:: Thomas Linkin (<trlinkin@gmail.com>)
    Copyright:: Copyright (c) 2013 Thomas Linkin
    License:: Apache License, Version 2.0

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
