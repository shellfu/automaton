# ~$ automaton
[![Code Climate](https://codeclimate.com/github/shellfu/automaton.png)](https://codeclimate.com/github/shellfu/automaton)

* * *
#### ~$ what is automaton
automaton is a lightweight external node classifier for puppet that supports multiple data backends. New backend storage
 mechanisms can be easily written for automaton. It has a simple command line interface, as well as an optional REST 
 interface. automaton is written in ruby, and authored by shellfu, just another unix admin out there.


#### ~$ why I wrote automaton

At my last gig we used puppet, and had a fairly large deployment. Large enough that a lot of different departments were 
asking for data. “What modules are on machineA vs machineB?”, “What parameters are applied to machineB? I need to overwrite them can I?”

We also started to store machine metadata like deploy time, undeploytime, availability zone/physical datacenter, 
network so on and so fourth. This data was then plugged into other custom tools, and at the time none of the current
ENC’s could provide this for me. I was having to write scripts to serialize the data from those ENC’s into something 
our developers and management could consume. Those scripts evolved into automaton.

One of the main goals of automaton was to ensure it was robust enough to plug into other tools such as deployment 
dashboards. At the same time it can also be used in a more lightweight fashion with just the command line and flat file 
support.

I wanted to pick and choose how and where I wanted my node data consumed and manipulated, and automaton solved this for 
me. If you like it great! Please shoot me a line with comments or suggestions. I hope I can help make your life a little
bit easier.


#### ~$ features
* rest interface
* command-line interface
* multi-node inheritance
* parameterized classes
* node fact storage via puppet's inventory service
* facter fact interpolation
* easy configuration via yaml
* db or flat file storage
    * mongodb
    * yaml
    * json

#### ~$ roadmap
* expand ability to modify hiera data (limited to hiera, and automaton sharing data dirs right now)
* a group system. cli,rest (it exists but isnt very apparent, and needs fleshing out)
* configurable metadata storage (to be a bolt on/plugin)
* documentation on writing a plugin

## ~$ documentation
* [basic usage](https://github.com/shellfu/automaton/wiki/usage::basic)
* [fact interpolation](https://github.com/shellfu/automaton/wiki/usage::topic::facter)
* [installation => command-line interface](https://github.com/shellfu/automaton/wiki/installation::command-line_interface)
* [installation => rest interface](https://github.com/shellfu/automaton/wiki/Installation::rest-interface)

##### ~$ contributing
if you wish to contribute to automaton just send a pull request over.
