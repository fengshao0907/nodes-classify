Gem::Specification.new do |s|
    s.name          = 'nodes'
    s.version       = '2.0.0.0'
    s.date          = '2013-06-19'
    s.summary       = 'nodes client'
    s.description   = 'machine manage use tags'
    s.authors       = ['Guy']
    s.email         = 'yangmengqing@baidu.com'
    s.homepage      = 'https://github.com/zerdliu/nodes-classify'
    s.files         = ['lib/nodes.rb', 'lib/nodes/sslconvert.rb', 'lib/nodes/req.rb', 'lib/nodes/exception.rb']
    s.executables   << 'nodes' << 'nodesck' << 'nodescp'
    s.rdoc_options  << '--charset' << 'UTF-8'
end
