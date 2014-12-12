Eye.config do
  logger "/opt/automaton/log/eye_automaton.log"
end

Eye.application("automaton") do |app|

  group "services" do

    process :unicorn do
      working_dir '/opt/automaton'
      pid_file "/var/run/automaton/automaton_unicorn.pid"
      stdall "/opt/automaton/log/eye_automaton.log"
      start_command   "bundle exec unicorn -c /opt/automaton/rack/automaton.conf -E production -D"
      stop_command    "kill -QUIT "
      restart_command "kill -USR2 " # for rolling restarts

      # ensure the memory and cpu
      check :memory, every: 30.seconds, below: 85.megabytes, times: [3, 4]
      check :cpu, below: 30, times: [3, 4]

      start_timeout 10.seconds
      stop_timeout 5.seconds

      monitor_children do
        restart_command 'kill -2 {PID}' # for this child process
        check :memory, below: 85.megabytes, times: 3
      end
    end

  end
end
