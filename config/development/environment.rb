# CloudFS 配置文件.
# =================

# 日志文件路径
#log_path    "log/#{ENV['RACK_ENV']}.log" # or $stdout

# 日志文件更新频率
#log_rolling 'daily' # or 'weekly', 'monthly', [10, 1024000]

# 日志级别（默认:info，注意前面是有一个冒号）
#log_level   :info # or :debug, :warn, :error, :fatal

# MongoDB的相关配置
mongo :host => '192.168.0.15'
#      :port => 27017,
#      :db   => 'files',
#      :timeout => 6

# 缩略图设置
## 缩略图大小的允许范围(单位：px）
thumbnail_size 1..256
## 允许缩略图的文件格式（正则表达式，字符串均可）
thumbnail_allow %r'\Aimage/'
## 是否允许缩略图比原文件大
thumbnail_enlarge false
