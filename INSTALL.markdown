# ~$ automaton installation instructions
The installation procedure is broken up into different pieces as some components of automaton are optional. We will start with the command-line interface as that is what puppet uses as its node terminus. I also find the command-line interface just plain handy as im always just a key away from a terminal.



#### Command-Line Interface Installation
###### clone the repository & bundle install
```bash
[shellfu@automaton]$ cd /opt
[shellfu@automaton opt]$ git clone https://github.com/shellfu/automaton.git
[shellfu@automaton opt]$ cd automaton
[shellfu@automaton opt]$ bundle install
```

###### edit config/config.yaml and optionally link automaton to /usr/bin:
```bash
[shellfu@automaton automaton]$ vim config/config.yml
[shellfu@automaton automaton]$ sudo ln -s /usr/bin/automaton /opt/automaton/bin/automaton_cli.rb
```
###### I also set the automaton directory to the user puppet runs as:
```bash
[shellfu@automaton automaton]$ sudo chown -R puppet:puppet /opt/automaton/
```

At this point you may go ahead and start using automaton. When you are ready you will want to change the node terminus inside your /etc/puppet.conf file.

