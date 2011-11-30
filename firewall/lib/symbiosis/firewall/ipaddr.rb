require 'ipaddr'
require 'pp'

module Symbiosis
class Firewall
class IPAddr < ::IPAddr
  include Enumerable

  def broadcast
    case @family
    when Socket::AF_INET
      @mask_addr = IN4MASK if @mask_addr > IN4MASK
      self.clone.set(self.network.to_i | ((~@mask_addr) & IN4MASK))
    when Socket::AF_INET6
      @mask_addr = IN6MASK if @mask_addr > IN6MASK
      self.clone.set(self.network.to_i | ((~@mask_addr) & IN6MASK))
    end
  end

  def network
    self.clone.set(@addr & @mask_addr)
  end
  
  alias max broadcast
  alias min network

  def each
    case @family
    when Socket::AF_INET
      (self.network.to_i..self.broadcast.to_i).each do |addr|
        yield self.clone.set(addr).mask!(32)
      end
    when Socket::AF_INET6
      (self.network.to_i..self.broadcast.to_i).each do |addr|
        yield self.clone.set(addr).mask!(128)
      end
    end
  end
  
  def <=>(other)
    @addr.to_i <=> other.to_i
  end

  def IPAddr.from_i(arg)
    if arg < 0xffffffff
      IPAddr.new((0..3).collect{|x| x*8}.collect{|x| (arg.to_i >> x & 0xff).to_s}.reverse.join("."))
    else
      IPAddr.new((0..7).collect{|x| x*16}.collect{|x| (arg.to_i >> x & 0xffff).to_s(16)}.reverse.join(":"))
    end
  end

  def range_to_s
    [_to_string(@addr), _to_string(@mask_addr)].join('/')
  end

  def cidr_mask
    #
    # Hmm.. this is a bit horrid.  But without a log2 function, there's not
    # much else we can do..
    case @family
    when Socket::AF_INET
      @mask_addr = IN4MASK if @mask_addr > IN4MASK
      n_addresses = ((~@mask_addr) & IN4MASK) + 1
      32 - (0..32).find{|m| 2**m == n_addresses}
    when Socket::AF_INET6
      @mask_addr = IN6MASK if @mask_addr > IN6MASK
      n_addresses = ((~@mask_addr) & IN6MASK) + 1
      128 - (0..128).find{|m| 2**m == n_addresses}
    end
  end
  
  def to_s
    [super, cidr_mask].join('/')
  end


end

end

end

