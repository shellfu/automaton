
module Automaton
  class NodeHelper
    def removal(new_hash, old_hash)
      if new_hash[:enc][:classes]
        class_name      = new_hash[:enc][:classes].split('^')
        class_parameter = class_name.pop
        class_name.inject(old_hash['enc']['classes']) { |h, el| h[el] }.delete class_parameter
      end
      old_hash['enc']['parameters'].delete( new_hash[:enc][:parameters].to_s ) if new_hash[:enc][:parameters]
      old_hash
    end

    def set_environment(new_environment, old_environment)
      return Automaton::Configure::config[:environment] if new_environment.to_s.empty? and old_environment.to_s.empty?
      return old_environment if new_environment.to_s.empty?
      new_environment
    end

    def set_parameters(new_hash, original_hash)
      new_hash = Hash[new_hash.split(',').map { |str| str.split('=') }.inject({}) { |c, (key, v)| c[key] = v; c }] unless new_hash.nil?
      return nil if original_hash.to_s.empty? and new_hash.to_s.empty?
      return new_hash if original_hash.to_s.empty?
      return original_hash if new_hash.to_s.empty?
      return original_hash.deep_merge(new_hash) if original_hash
      new_hash
    end

    def set_classes(new_hash, original_hash)
      new_hash = Hash[new_hash.split(',').map{ |s| k, *v = s.split('^'); [k, v.empty? ? nil : Hash[v.map{|x|x.split('=')}]]}] unless new_hash.nil?
      return nil if original_hash.to_s.empty? and new_hash.to_s.empty?
      return new_hash if original_hash.to_s.empty?
      return original_hash if new_hash.to_s.empty?
      return original_hash.deep_merge(new_hash) if original_hash
      new_hash
    end

    def set_inherits(new_inherits, old_inherits)
      return nil if new_inherits.to_s.empty? and old_inherits.to_s.empty?
      return old_inherits if new_inherits.to_s.empty?
      new_inherits
    end
  end
end