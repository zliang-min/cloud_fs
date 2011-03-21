module AssetsHelper
  def spec_root
    @spec_root ||= Pathname(__FILE__).dirname.join('..').expand_path
  end

  def empty_gif
    spec_root.join('assets/empty.gif')
  end

  def md5_of_empty_gif
    Digest::MD5.hexdigest(File.read(empty_gif))
  end
end
