# ~$ automaton installation instructions
The installation procedure is broken up into different pieces as some components of automaton are optional. We will start with the command-line interface as that is what puppet uses as its node terminus. I also find the command-line interface just plain handy as im always just a key away from a terminal.

#### Command-Line Interface Installation
The command-line interface is what puppet will use to classify nodes via it's node terminus. Its also what is used to manipulate node data on the command-line. Since puppet requires ruby I won't go into it's installation, and will leave that up to your method of choice

###### clone the repository & bundle install
```bash
[shellfu@automaton]$ cd /opt
[shellfu@automaton opt]$ git clone https://github.com/shellfu/automaton.git
[shellfu@automaton opt]$ cd automaton
[shellfu@automaton opt]$ bundle install
```

###### edit config/config.yaml and optionally link automaton to /usr/bin:
The config.yml file is documented, and is straight forward. Simply enter your environment specific settings, and save the file. If you are using *:database_type = 'yaml'* then you can create your data path now, or automaton will do this for you. It's entirely up to you. 
```bash
[shellfu@automaton automaton]$ vim config/config.yml
[shellfu@automaton automaton]$ sudo ln -s /usr/bin/automaton /opt/automaton/bin/automaton_cli.rb
```

###### chown the automaton directory to the user puppet runs as:
```bash
[shellfu@automaton automaton]$ sudo chown -R puppet:puppet /opt/automaton/
```

At this point you may go ahead and start using automaton. When you are ready you will want to change the node terminus inside your **/etc/puppet.conf** file.

