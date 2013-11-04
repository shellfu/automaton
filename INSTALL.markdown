### ~$ automaton cli interface installation
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
The config.yml file is documented, and is straight forward. Simply enter your environment specific settings, and save the file. If you are using **:database_type = 'yaml' or 'json'** then create your data path now. If you are using **MongoDB** then you may skip the creation of the data path.
```bash
[shellfu@automaton automaton]$ vim config/config.yml
[shellfu@automaton automaton]$ mkdir -p /opt/automaton/data/nodes/
[shellfu@automaton automaton]$ sudo ln -s /opt/automaton/bin/automaton_cli.rb /usr/bin/automaton
```

###### chown the automaton directory to the user puppet runs as:
```bash
[shellfu@automaton automaton]$ sudo chown -R puppet:puppet /opt/automaton/
```

At this point you may go ahead and start using automaton. When you are ready you will want to change the node terminus inside your **/etc/puppet.conf** file.

* * *

### ~$ automaton rest interface installation
Before continuing be sure you have already completed the command-line interface installation instructions.

###### Create Directories & Set Permissions
```bash
[shellfu@automaton automaton]$ sudo mkdir /var/run/automaton/
[shellfu@automaton automaton]$ sudo chown -R puppet:puppet /var/run/automaton/
```

###### Configure Nginx & Unicorn, Alter Path in confif.ru and Link config.ru
If you cloned the repository into /opt/ then you should not need to modify the >**require '/opt/automaton/bin/automaton'**< line, and can simply move onto linking config.ru.
```bash
[shellfu@automaton automaton]$ sudo cp rack/14567_automaton.conf /etc/nginx/conf.d/
[shellfu@automaton automaton]$ sudo vim /etc/nginx/conf.d/14567_automaton.conf
[shellfu@automaton automaton]$ sudo vim rack/automaton.conf
[shellfu@automaton automaton]$ sudo vim rack/config.ru
[shellfu@automaton automaton]$ sudo ln -s /opt/automaton/rack/config.ru /opt/automaton/config.ru
```

###### Reload Nginx & Load Automaton
```bash
[shellfu@automaton automaton]$ sudo service nginx reload
[shellfu@automaton automaton]$ bundle exec unicorn -c ./rack/automaton.conf