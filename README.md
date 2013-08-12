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
