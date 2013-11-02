# ~$ automaton
[![Code Climate](https://codeclimate.com/github/shellfu/automaton.png)](https://codeclimate.com/github/shellfu/automaton)

Automaton is an external node classifier for puppet. Its goal is to ease the creation of node definitions, and support a variety of data backends.

#### Why I Wrote This:
At my last gig we used puppet, and had a fairly large deployment. Large enough that a lot of different departments were asking for data. *"What modules are on machineA vs machineB?"*, *"What parameters are applied to machineB? I need to overwrite them can I?"*

We also started to store machine metadata like deploy time, undeploytime, availability zone/physical datacenter, network so on and so fourth. This data was then plugged into other custom tools, and at the time none of the current ENC's could provide this for me. I was having to write scripts to serialize the data from those ENC's into something our developers and management could consume. Those scripts evolved into automaton.

One of the main goals of automaton was to ensure it was robust enough to plug into other tools such as deployment dashboards. At the same time it can also be used in a more lightweight fashion with just the command line and flat file support.

I wanted to pick and choose how and where I wanted my node data consumed and manipulated, and automaton solved this for me. If you like it great! Please shoot me a line with comments or suggestions. 

**Contributing**  
_If you wish to contribute to automaton just send a pull request over. You can add new data backends or whatever. Just shoot a pull request, and ill be sure to review it._

#### Features:
* REST Interface
* Separate Command Line Interface
* Multi-Node Inheritance
* Parameterized Classes
* Node Fact Storage
* Fact Interpolation
* Easy Configuration via config.yml
* Database or Flat-File Storage
    * MongoDB
    * YAML

#### RoadMap:
* JSON Flat File Support
* Configurable Metadata Storage
* Setup Script for Easy Configuration
* Convert config files to erb templates to be fed from setup script

#### Requirements:
* Ruby 1.8.7p352 or higher
* Rubygems if not using Ruby 1.9.3
* Rails Server if REST interface is used

### Installation Overview:
Lets go over the installation and configuration of automaton starting with an overview of steps. 

##### Command Line Only:
1. Clone the Git Repository 
2. Edit config.yml
3. Done 

##### REST Interface:
1. Clone the Git Repository 
2. Edit config.yml
3. Create Webserver config file
4. Create Rails server config file
5. Restart/Reload Webserver and Rails server
6. Done

##### Optional Tasks:
1. Create symlink for */usr/bin/automaton > /path/to/automaton/bin/automaton_cli.rb*
2. Setup process monitoring 

#### Manual Installation:
This is the manual process to install automaton. We will go over command line support only then move onto setting up the REST interface on a Unicorn rails server.

##### Command Line Support Only
###### Clone the Automaton Repository & Install Gems:
```bash
[shellfu@automaton]$ cd /opt
[shellfu@automaton opt]$ git clone https://github.com/shellfu/automaton.git
[shellfu@automaton opt]$ cd automaton
[shellfu@automaton opt]$ bundle install
```

###### Edit config/config.yml & Set Permissions & lnk automaton to /usr/bin:
```bash
[shellfu@automaton automaton]$ vim config/config.yml
[shellfu@automaton automaton]$ sudo chown -R puppet:puppet /opt/automaton/
[shellfu@automaton automaton]$ sudo ln -s /usr/bin/automaton /opt/automaton/bin/automaton_cli.rb
```

At this point you may start using automaton with command line support only. You can continue on to enable the REST interface if you so choose.


##### REST Interface

###### Create Directories & Set Permissions
```bash
[shellfu@automaton automaton]$ sudo mkdir /var/run/automaton/
[shellfu@automaton automaton]$ sudo chown -R puppet:puppet /var/run/automaton/
```

###### Configure Nginx & Unicorn, and Link config.ru
```bash
[shellfu@automaton automaton]$ sudo cp rack/14567_automaton.conf /etc/nginx/conf.d/
[shellfu@automaton automaton]$ sudo vim /etc/nginx/conf.d/14567_automaton.conf
[shellfu@automaton automaton]$ vim rack/automaton.conf
[shellfu@automaton automaton]$ ln -s /opt/automaton/rack/config.ru /opt/automaton/config.ru
```

###### Reload Nginx & Load Automaton
```bash
[shellfu@automaton automaton]$ sudo service nginx reload
[shellfu@automaton automaton]$ sudo vim /etc/nginx/conf.d/14567_automaton.conf
[shellfu@automaton automaton]$ bundle exec unicorn -c ./rack/automaton.conf
```

#### Quick Installation:
_**not yet implemented... coming soon**_  
For a quick installation, and configuration of automaton run the setup script. The setup script will guide you through a series of questions and configure automaton based off your input. It also creates a symlink in */usr/bin/automaton > /path/to/automaton/bin/automaton_cli.rb*  

```bash
[shellfu@automaton]$ cd /opt
[shellfu@automaton opt]$ git clone https://github.com/shellfu/automaton.git
[shellfu@automaton opt]$ cd automaton 
[shellfu@automaton automaton]$ ruby setup.rb 
```

## Usage

#### Quick Usage
Both CLI and API have very similar formats to make it easy to remember. Take note of the below delimiters when adding class parameters or top level parameters. 

For class parameters you specify like: **timezone^timezone=Europe/Berlin**.  
For top parameters you specify like: **key=value,key1=value**. 

This format holds true on both the CLI and the API. I'm not going to go over update as its the same as the addition format.
```ruby
#CLI / API
:n,  :name        #( nodename )
:e,  :environment #( environment or blank as set in config.yml )
:c,  :classes     #( foo^key=value^key1=value1,bar,foo-bar ) # Adds class foo w/ params key & key1, class bar, class foo-bar
:p,  :parameters  #( key=value,key2=value2 )
:i,  :inherit     #( blank or node to inherit classes from )
```

In addition to the above each command has its own help. 
```bash
[shellfu@automaton] automaton --help
usage: automaton [command] [options]

Available commands:

  lookup   Look up a node by name and return class information
  add      Add a node to the mongo ENC
  update   Update a node in the mongo ENC
  remove   Removes a node in the mongo ENC
  facts    Retrieves and Keeps Facts up to date

[shellfu@automaton] automaton lookup --help
usage: automaton [command] [options]

    -n, --name         The name or fqdn of the node you want to lookup
    -h, --help         Display this help message.

```

#### Usage
It's time to learn how to use this thing right? I'll go over node lookups, additions, updates.

###### Adding a Node
So below we are going to add a default node definition, add the timezone class, set the timezone class parameter.
```bash
[shellfu@automaton] automaton add -n default -c timezone^timezone=Europe/Berlin
INFO: Node >default< has been added to the ENC.
```

###### Lookup a Node
The below command is exactly what puppet will run to retreive a node definition. 
```bash
[shellfu@automaton] automaton lookup -n default
---
environment: production
classes:
  timezone:
    timezone: Europe/Berlin
parameters: 
```

###### Update a Node
So below we are going to add a default node definition, add the timezone class, set the timezone class parameter.
```bash
[shellfu@automaton] automaton update -n default -c timezone^timezone=America/Denver
INFO: Node >default< Updated
```  
 
Checking our update
```bash
[shellfu@automaton] automaton lookup -n default
---
environment: production
classes:
  timezone:
    timezone: America/Denver
parameters: 
```

###### Remove a Node
You can remove a node, class or parameter.

Removing a Class:
```bash
[shellfu@automaton] automaton remove -n default -c timezone
INFO: Class >timezone< Removed from >default< in the ENC 
```

Removing a Node:
```bash
[shellfu@automaton] automaton remove -n default
INFO: Node >default< Removed from ENC
```
