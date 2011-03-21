module CloudFS
  module Action
    autoload :Base,   'cloud_fs/action/base'
    #autoload :HEAD,   'cloud_fs/action/head'
    autoload :GET,    'cloud_fs/action/get'
    autoload :POST,   'cloud_fs/action/post'
    #autoload :PUT,    'cloud_fs/action/put'
    #autoload :DELETE, 'cloud_fs/action/delete'
  end
end
