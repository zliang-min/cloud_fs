# CloudFS 分布式文件系统

## 环境需求
* Ruby 1.9.2+
* MongoDB 1.4.2 或以上
* ImageMagick 建议通过软件包管理系统(如yum、apt等)来安装，如果没有的话，可以直接从[官网下载](http://www.imagemagick.org/script/download.php)安装
* Ruby gems:
  * bundler ~> 1.0.7
  * eventmachine ~> 0.12.10
  * rainbows ~> 2.1.0
**说明**
* 程序里使用到了一些Ruby 1.9所特有的方法，所以用1.8跑是会报错的，而且测试下来的结果，使用1.9的效率要比使用1.8快上一倍多。
* [rainbows](http://rainbows.rubyforge.org/)是一个ruby的web服务器（类似于thin），经过多次测试，rainbows配合CloudFS的效率是最好的，所以推荐使用。rainbows可以直接使用，不需要跟nginx一起使用（当然要一起也是可以的）。rainbows本身就像是一个nginx + thin，它会启动一个主进程（控制进程，相当于nginx），若干个子进程（工作进程，相当于thin），来运行程序。

## 安装方法
1. `git clone git://github.com/Gimi/cloud_fs.git`
2. `cd /var/www/cloud_fs`
3. `bundle install --local --deployment` （bundle是安装了bundler之后附带的脚本）
4. `vim config.rb` (修改相关的配置参数）
5. `cp scripts/rainbows.rb /etc/rainbows/cloud_fs.rb` （rainbows.rb是一个rainbows的配置样例）
6. `vim /etc/rainbows/cloud_fs.rb` （根据实际情况，修改配置）
**注意**
* 以上路径，均是示范，根据实际情况修改

## 运行
    $> # rainbows是安装了rainbows之后附带的脚本，各参数的意义可通过rainbows -h来获取
    $> rainbows -D -E production -c /etc/rainbows/cloud_fs.rb /var/www/cloud_fs/config.ru

## 更新
1. 更新程序代码
2. 执行`bundle install`
3. 重启rainbows
rainbows对信号的支持非常全面，[详细](http://rainbows.rubyforge.org/SIGNALS.html)。所以重启非常简单，只要在更新了程序的代码之后，执行：
    kill -1 [rainbows的主进程id] 或 kill -s HUP [rainbows的主进程id]
就可以完成更新了。

## 数据库集合创建规则
程序会自动根据访问的地址的子域名来把文件保存到不同的集合里面。
比如子域名是：image.51hejia.com，那么文件将会保存到image.files和image.chunks中，如果文件是图片，那么还将会使用image.thumbnails.files和image.thumbnails.chunks两个集合来保存缩略图。
子域名只考虑第一级的，所以assets1.image.51hejia.com和assets2.image.51hejia.com和image.51hejia.com访问的都是image这个集合。

如果不能从域名中解析出集合的位置，默认为files。

## TODOs
* Reduce db queries.
