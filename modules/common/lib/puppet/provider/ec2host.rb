class Puppet::Provider::Ec2host < Puppet::Provider
  def self.prefetch(hosts)
    instances.each do |prov|
      if host = hosts[prov.name]
        host.provider = prov
      end
    end
  end

  def flush
    @property_hash.clear
  end

  def properties
    if @property_hash.empty?
      @property_hash = query || {:ensure => :absent}
      @property_hash[:ensure] = :absent if @property_hash.empty?
    end
    @property_hash.dup
  end

  def query
    self.class.instances.each do |host|
      if host.name == self.name or host.name.downcase == self.name
        return host.properties
      end
    end
    nil
  end

  def exists?
    properties[:ensure] != :absent
  end
end
