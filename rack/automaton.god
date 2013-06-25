God.watch do |w|
  w.name     = "automaton"
  w.interval = 30.seconds
  w.pid_file = "/var/run/automaton/automaton_unicorn.pid"
  w.log      = "/opt/tzg/automaton/unicorn_automaton.log"
  w.dir      = "/opt/tzg/automaton"

  w.start   = 'ulimit -v 750000 && exec /opt/tzg/ruby/bin/unicorn -c /opt/tzg/automaton/rack/automaton.conf -D'
  w.stop    = "kill -QUIT `cat #{w.pid_file}`"
  w.restart = "kill -USR2 `cat #{w.pid_file}`"

  w.start_grace   = 10.seconds
  w.restart_grace = 10.seconds

  w.uid = "puppet"
  w.gid = "puppet"

  w.behavior(:clean_pid_file)

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits)
  end

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running  = false
    end
  end
end
