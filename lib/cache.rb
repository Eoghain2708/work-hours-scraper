require "fileutils"

module Cache
  DIR = File.join(Dir.home, ".cache", "shifts")


  def self.dir 
    DIR
  end
  def self.read(name)
    path = path(name)
    return nil unless File.exist?(path)
    return nil if File.zero?(path)

    File.read(path)
  end

  def self.write(name, contents)
    ensure_dir
    File.write(path(name), contents)
  end
  
  def self.exist?(name)
    File.exist?(path(name))
  end

  def self.empty?(name)
    File.zero?(path(name))
  end

  private 
  def self.ensure_dir
    FileUtils.mkdir_p(DIR)
  end

  def self.path(name)
    File.join(DIR, name)
  end

  
  
end