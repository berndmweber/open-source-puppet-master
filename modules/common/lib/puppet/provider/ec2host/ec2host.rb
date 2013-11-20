require 'puppet/provider/ec2host'
require 'puppet/provider/parsedfile'

ec2hosts = nil
case Facter.value(:osfamily)
when "Debian"; ec2hosts = "/etc/cloud/templates/hosts.tmpl"
end


Puppet::Type.type(:ec2host).provide(:parsed,:parent => Puppet::Provider::ParsedFile,
  :default_target => ec2hosts,:filetype => :flat) do
  confine :exists => ec2hosts

  text_line :comment, :match => /^#/
  text_line :blank, :match => /^\s*$/

  record_line :parsed, :fields => %w{ip name host_aliases comment},
    :optional => %w{host_aliases comment},
    :match    => /^(\S+)\s+(\S+)\s*(.*?)?(?:\s*#\s*(.*))?$/,
    :post_parse => proc { |hash|
      # An absent comment should match "comment => ''"
      hash[:comment] = '' if hash[:comment].nil? or hash[:comment] == :absent
      unless hash[:host_aliases].nil? or hash[:host_aliases] == :absent
        hash[:host_aliases].gsub!(/\s+/,' ') # Change delimiter
      end
    },
    :to_line  => proc { |hash|
      [:ip, :name].each do |n|
        raise ArgumentError, "#{n} is a required attribute for hosts" unless hash[n] and hash[n] != :absent
      end
      str = "#{hash[:ip]}\t#{hash[:name]}"
      if hash.include? :host_aliases and !hash[:host_aliases].nil? and hash[:host_aliases] != :absent
        str += "\t#{hash[:host_aliases]}"
      end
      if hash.include? :comment and !hash[:comment].empty?
        str += "\t# #{hash[:comment]}"
      end
      str
    }
end
