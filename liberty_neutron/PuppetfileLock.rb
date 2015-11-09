require 'r10k/puppetfile'


module R10K 
  class Puppetfile
    def freeze
      @modules.each do |m| 
        puts "mod '#{m.title}'#{m.freeze}"
      end
    end
  end
end

class R10K::Module::Base  
  # default implementation
  def freeze
  end
end

class R10K::Module::Git
  def freeze 
    @repo.freeze(@ref)
  end

end


class R10K::Git::StatefulRepository
  def freeze(ref)
    ",
    :git => '#{@remote}',
    :ref => '#{@cache.resolve(ref)}'"
  end

end


puppetfile = R10K::Puppetfile.new('.', puppetfile = 'Puppetfile')
puppetfile.load
puppetfile.freeze
