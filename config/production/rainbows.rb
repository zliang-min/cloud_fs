=begin
# 这里是示范listen所接受的所有参数
listen 4000, :backlog => 1024,
             :rcvbuf => system_default,
             :sndbuf => system_default,
             :tcp_nodelay => false,
             :tcp_nopush => ??,
             :tries => 5,
             :delay => 0.5,
             :umask => 0
=end
root = File.expand_path '../../..', __FILE__

listen 81, :tcp_nodelay => true, :tcp_nopush => true

# 超时一般按默认的就可以了
# timeout 60

# 子进程数(一般按照cpu的个数或者核数来确定）
worker_processes 4 # 可以通过 kill -s SIGTTIN和kill -s SIGTTOUT来增减

# 是否预读程序代码，一般选false
preload_app false

# 主进程pid文件的位置
pid '/var/rainbows/cloud_fs.pid'

log_file = '/var/log/rainbows/cloud_fs.log'
# 日志，第一个字符串是日志的位置，第二个是日记更新的频率，可以选：'daily', 'weekly', 'monthly'
logger Logger.new log_file, 'daily'

# 标准错误输出转向
stderr_path log_file

# 标准输出转向
stdout_path log_file

# ** logger, stderr_path, stdout_path三个可以指向同一个文件

# 工作路径，一般是程序的跟路径
working_directory root

# 设置用户和用户组
user 'deploy', 'deploy'

# 下面的三个一般不需要使用
#before_exec {}
#before_fork {}
#after_fork {}

Rainbows! do
  # 设置并发模型，暂时测试下来，EventMachine的效果比较好
  #use :EventMachine
  use :Coolio

  # 每个工作进程可以同时处理的连接数，应该根据服务器的配置、性能来配置。
  # rainbows所能处理的客户端连接数 = worker_processes x worker_connections
  worker_connections 100

  # keepalive的超时时间，0为不支持keepalive
  keepalive_timeout  0

  # 最大的请求大小，默认为1MB
  #client_max_body_size 1 * 1024 * 1024 # 1MB
end
