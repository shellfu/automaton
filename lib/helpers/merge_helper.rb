module HashRecursiveMerge

  class BSON::OrderedHash
    def to_h
      inject({}) { |key, value| k, v = value; key[k] = ( if v.class == BSON::OrderedHash then v.to_h else v end); key }
    end

    def to_json
      to_h.to_json
    end

    def to_yaml
      to_h.to_yaml
    end
  end

  def deep_merge!(specialized_hash)
    return internal_deep_merge!(self, specialized_hash)
  end


  def deep_merge(specialized_hash)
    return internal_deep_merge!(Hash.new.replace(self), specialized_hash)
  end

  def convert_bson_hash
    BSON::OrderedHash::to_h
  end

  protected

  # better, recursive, preserving method
  # OK OK this is not the most efficient algorithm,
  # but at last it's *perfectly clear and understandable*
  # so fork and improve if you need 5% more speed, ok ?
  def internal_deep_merge!(source_hash, specialized_hash)

    #puts "starting deep merge..."

    specialized_hash.each_pair do |rkey, rval|
      #puts " potential replacing entry : " + rkey.inspect

      if source_hash.has_key?(rkey) then
        #puts " found potentially conflicting entry for #{rkey.inspect} : #{rval.inspect}, will merge :"
        if rval.is_a?(Hash) and source_hash[rkey].is_a?(Hash) then
          #puts " recursing..."
          internal_deep_merge!(source_hash[rkey], rval)
        elsif rval == source_hash[rkey] then
          #puts " same value, skipping."
        else
          #puts " replacing."
          source_hash[rkey] = rval
        end
      else
        #puts " found new entry #{rkey.inspect}, adding it..."
        source_hash[rkey] = rval
      end
    end

    #puts "deep merge done."

    return source_hash
  end

end

class Hash
  include HashRecursiveMerge
end