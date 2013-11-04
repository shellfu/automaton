# ~$ automaton
[![Code Climate](https://codeclimate.com/github/shellfu/automaton.png)](https://codeclimate.com/github/shellfu/automaton)

* * *
automaton is a lightweight external node classifier for puppet that supports multiple data backends. New backend storage mechanisms can be easily written for automaton. It has a simple command line interface, as well as an optional REST interface. automaton is written in ruby, and authored by shellfu, just another unix admin out there.

#### ~$ features
* command-line interface
* rest interface
* multi-node inheritance compressed to single hash
* parameterized classes
* node fact storage via puppet's inventory service
* facter fact interpolation
* easy configuration via yaml
* db or flat file storage
    * mongodb
    * yaml
    * json

#### ~$ roadmap
* configurable metadata storage (to be a bolt on/plugin)
* documentation on writing a plugin

## ~$ documentation
* [basic usage](https://github.com/shellfu/automaton/wiki/usage::basic)
* [installation => command-line interface](https://github.com/shellfu/automaton/wiki/installation::command-line_interface)
* [installation => rest interface](https://github.com/shellfu/automaton/wiki/Installation::rest-interface)

##### ~$ contributing
if you wish to contribute to automaton just send a pull request over.


