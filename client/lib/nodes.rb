#encoding: utf-8

require 'digest'
require 'openssl'

class Nodes
    HTTP_REQUEST_ERROR = 100
    ILLEGAL_STATUS = 101
    UNRECOGNIZED_COMMAND = 102
    IDENTIFY_FILE_ERROR = 103
    AUTH_ERROR = 104
    ILLEGAL_OPTION = 105
    INSERT_NODE_ERROR = 106
    PUBLICKEY_FILE_ERROR = 107
    PUBLICKEY_TYPE_ERROR = 108
    NO_PL_ERROR = 109
    ADD_PUBKEY_ERROR = 110
    READ_FILE_ERROR = 111
    UNKNOW_ERROR = 112

    #DEFAULT_SER_URI = 'http://ai-imci-control01.ai01.baidu.com:8090/nodes'
    DEFAULT_SER_URI = 'http://m1-sf-preonline00.m1:8090'
    LEGAL_STATUS = %w{ running offline }

    VERSION = 'Nodes Client: 2.0.0.0 (2013-06-19)'

    attr_reader :authenticated

    #
    # new instance method
    #
    # - opt
    #     参数hash表，目前仅读取:service_uri键值作为nodes服务URL
    #
    def initialize(opt={})
        @req = Req.new(opt[:service_uri] || DEFAULT_SER_URI)
        @authenticated = false
    end

    #
    # 查找nodes
    #
    # - tag_expression
    #     tag组成的逻辑表达式，支持, + [ ]操作符
    #
    # - status
    #     返回的nodes状态。默认返回所有状态的主机,可省略
    #
    # - exclude
    #     要排除的主机名的正则表达式,可省略
    #
    def search_nodes(project, tag_expression = nil, status = nil, exclude = /^$/)
        raise Nodes::Exception.new(ILLEGAL_STATUS, 'illegal status: %s' % status) unless legal_status?(status)
        if tag_expression.nil? 
            uri = "/nodes/search/#{project}"
        else
            tag_expression = URI.escape(Base64.encode64(tag_expression))
            uri = "/nodes/search/#{project}/#{tag_expression}"
        end
        uri += "/#{status}" if status
        res = @req.get(uri)
        res['data'].reject! { |data| data['name'] =~ /#{exclude}/ } if res['status'] == 0
        res
    end

    #
    # 根据主机名查找对应的tag
    #
    # - node_name
    #     主机名
    #
    def search_tags(node_name)
        node_name = URI.escape(Base64.encode64(node_name))
        @req.get("/tags/search/#{node_name}")
    end

    def search_tagseg(project, tag)
        tag_name = URI.escape(Base64.encode64(tag))
        raise Nodes::Exception.new(NO_PL_ERROR, "you shold specify the project (-p ) parameter") if project == nil
        @req.get("/tags/searchsegment/#{project}/#{tag_name}")
    end

    def search_taglist(project, segment)
        raise Nodes::Exception.new(NO_PL_ERROR, "you shold specify the project (-p ) parameter") if project == nil
        segment_name = URI.escape(Base64.encode64(segment))
        @req.get("/tags/taglist/#{project}/#{segment_name}")
    end

    #
    # 检查指定的状态是否为合法的状态
    #
    # - status
    #     指定的主机状态，当值为running,offline,nil时返回真。
    #
    def legal_status?(status)
        LEGAL_STATUS.include?(status) || status == nil
    end

    #
    # 使用shell命令读取文件，使支持 $HOME,~ 特殊字符
    #
    # - file
    #     file path
    #
    def self.read_file(file)
        res = `cat #{file} 2>/dev/null`
        return nil unless $?.success?
        res
    end

    #
    # 使用私钥认证
    #
    # - identify_file
    #     私钥文件，仅支持rsa和dsa两种格式。如果未指定该参数，则尝试$HOME/.ssh/{id_dsa,id_rsa}
    #
    def authentication(identify_file = nil)
        if not identify_file
            identify_file = `echo $HOME`.chomp + '/.ssh/id_dsa'
            identify_file = `echo $HOME`.chomp + '/.ssh/id_rsa' unless File.exist? identify_file
            raise Nodes::Exception.new(PUBLICKEY_FILE_ERROR, 'no identify file found!') unless File.exist? identify_file
        else
            raise Nodes::Exception.new(PUBLICKEY_FILE_ERROR, "No such identify file at:#{@options[:identify_file]}") unless File.exist? identify_file
        end

        keydata = File.read identify_file
        keytype = 'rsa' if keydata.start_with?('-----BEGIN RSA PRIVATE KEY-----')
        keytype = 'dsa' if keydata.start_with?('-----BEGIN DSA PRIVATE KEY-----')
        raise Nodes::Exception.new(IDENTIFY_FILE_ERROR, 'illegal identify file!support rsa or dsa only') unless %w{ rsa dsa }.include?(keytype)

        pkey = keytype == 'rsa' ? OpenSSL::PKey::RSA.new(keydata) : OpenSSL::PKey::DSA.new(keydata)
        pubmd5 = Digest::MD5.hexdigest(pkey.public_key.to_pem)
        data = @req.get("/preauth/#{pubmd5}")
        raise Nodes::Exception.new(AUTH_ERROR, data['msg']) if data['status'] == 1

        server_info = Base64.decode64 data['server_info']
        client_info = Base64.encode64(case keytype
            when 'rsa'; pkey.private_decrypt server_info
            when 'dsa'; pkey.syssign server_info
        end)
        data = @req.post("/auth", {'client_info' => client_info})
        raise Nodes::Exception.new(AUTH_ERROR, data['msg']) if data['status'] == 1
        @authenticated = true
    end

    #
    # 创建新的nodes
    #
    # - :nodes => 
    # - :tags =>
    # - :status =>
    # - :from_file =>
    # - :idenfity_file =>
    #
    def create_nodes(opt = {})
        write_node('insert', '/nodes/create', opt)
    end

    def update_nodes(opt = {})
        write_node('change', '/nodes/update', opt)
    end

    def delete_nodes(opt = {})
        write_node('delete', '/nodes/delete', opt)
    end

    #
    # 创建新的tags
    #
    # - :tags =>
    # - :segment =>
    # - :description =>
    # - :from_file =>
    # - :identify_file =>
    #
    def create_tags(opt = {})
        write_tag('insert', '/tags/create', opt)
    end

    def delete_tags(opt = {})
        write_tag('delete', '/tags/delete', opt)
    end

    #
    # 创建新的projects
    #
    # - :projects =>
    # - :description =>
    # - :from_file =>
    # - :identify_file =>
    #
    def create_projects(opt = {})
        write_project('insert', '/projects/create', opt)
    end

    def delete_projects(opt = {})
        write_project('delete', '/projects/delete', opt)
    end

    # 创建新的tagsegments
    #
    # - :segments =>
    # - :description =>
    # - :from_file =>
    # - :identify_file =>
    #
    def create_segments(opt = {})
        write_segment('insert', '/tagsegments/create', opt)
    end

    def delete_segments(opt = {})
        write_segment('delete', '/tagsegments/delete', opt)
    end

    #
    # 增加公钥
    #
    # - pubkey_file
    #     公钥文件
    #
    # - product_line
    #     产品线名称
    #
    # - identify_file
    #     用于执行该操作认证身份的私钥文件
    #
    def add_authkey(pubkey_file, product_line, identify_file = nil)
        raise Nodes::Exception.new(PUBLICKEY_FILE_ERROR, 'please specified a public key file you would add!') if Nodes.empty?(pubkey_file)
        raise Nodes::Exception.new(NO_PL_ERROR, 'please specified the product line!') if Nodes.empty?(product_line)
        raise Nodes::Exception.new(PUBLICKEY_FILE_ERROR, "no such file at:#{pubkey_file}") if (pubkey = Nodes.read_file(pubkey_file)) == nil

        keytype = nil;
        keytype = 'rsa' if pubkey.start_with?('ssh-rsa')
        keytype = 'dsa' if pubkey.start_with?('ssh-dss')
        raise Nodes::Exception.new(KEY_TYPE_ERROR, 'not support key type, can only use rsa or dsa key') if keytype.nil?

        pubkey = keytype == 'rsa' ? SSLConvert.rsa_pub_ssh2pem(pubkey) : SSLConvert.dsa_pub_ssh2pem(pubkey)

        form = {
            'usergroup' => product_line,
            'keytype' => keytype,
            'keydata' => pubkey
        }
        authentication(identify_file) unless @authenticated
        resp = @req.post('/auth_keys', form)
        raise Nodes::Exception.new(ADD_PUBKEY_ERROR, resp['msg']) unless resp['status']
    end

    def self.empty?(obj)
        return true unless defined?(obj) && obj != nil
        return true if obj.length == 0
        return false
    end

    private
    def write_node(type, uri, opt = {})
        write_operation([:nodes, :projects, :tags, :status], type, uri, opt)
    end

    def write_tag(type, uri, opt = {})
        write_operation([:tags, :projects, :segments, :description], type, uri, opt)
    end

    def write_project(type, uri, opt = {})
        write_operation([:projects, :description], type, uri, opt)
    end

    def write_segment(type, uri, opt = {})
        write_operation([:segments, :description], type, uri, opt)
    end

    def write_operation(seg, type, uri, options = {})
        raise Nodes::Exception.new(ILLEGAL_OPTION, 'Please specify the %s you would %s!' % [seg[0].to_s, type]) if Nodes.empty?(options[seg[0]]) && Nodes.empty?(options[:from_file])
        authentication(options.has_key?(:identify_file) ? options[:identify_file] : nil) unless @authenticated
        opt = []
        length = seg.length
        unless Nodes.empty?(options[seg[0]])
            case length 
            when 2
                opt.push('%s:%s' % [options[seg[0]], options[seg[1]]])
            when 4
                opt.push('%s:%s:%s:%s' % [options[seg[0]], options[seg[1]], options[seg[2]] || '', options[seg[3]]])
            end
        else
            raise Nodes::Exception.new(READ_FILE_ERROR, "read file at:#{options[:from_file]} failed!") if (file_content = Nodes.read_file(options[:from_file])) == nil
            opt = file_content.split(/\r|\n|\r\n/)
            opt.map! { |v| v.strip }
            opt.select! { |v| !Nodes.empty?(v) && !v.start_with?('#') }
        end

        failed = []; successed = []; success = 0; total = 0
        puts "\033[1;34mDealing:\033[0m"
        opt.each do |v|
            va = v.split(':')
            print "\r\033[K\t#{va[0]}\033[5m...\033[0m"
            total += va[0].split(',').length
            if length == 2
                form = [[seg[0].to_s, va[0]], [seg[1].to_s, va[1] || options[seg[3]]]]
            else
                form = case type
                    when 'delete'
                        failed.push(va[0]+':please specified the %s of these nodes' % seg[1].to_s) and next if va.length < 2 || Nodes.empty?(va[1])
                        [[seg[0].to_s, va[0]], [seg[1].to_s, va[1]]]
                    when 'insert'
                        failed.push(va[0]+':please specified the %s of these nodes' % seg[1].to_s) and next if va.length < 2 || Nodes.empty?(va[1])
                        failed.push(va[0]+':please specified the %s of these nodes' % seg[2].to_s) and next if va.length < 3 || Nodes.empty?(va[1])
                        [[seg[0].to_s, va[0]], [seg[1].to_s, va[1]], [seg[2].to_s, va[2]], [seg[3].to_s, va[3] || options[seg[3]]]]
                    when 'change'
                        failed.push(va[0]+':%s and %s specify at least one' % [seg[1].to_s, seg[2].to_s]) and next if va.length < 2
                        failed.push(va[0]+':please specified the %s of these nodes' % seg[2].to_s) and next if va.length < 3 || Nodes.empty?(va[1])
                        [[seg[0].to_s, va[0]], [seg[1].to_s, va[1]], [seg[2].to_s, va[2]], [seg[3].to_s, va[3] || options[seg[3]]]]

                end
            end
            res = @req.post(uri, form)

            failed.push(v+' execute failed! msg:'+res['msg']) and next if res['status'] == 1
            failed.push(res['failed']) if res['failed']
            successed.push(res['successed']) if res['successed']
            success += res['success']
        end
        puts "\r\033[K\tfinished."
        {:failed => failed, :successed => successed, :total => total, :success => success}
    end
end

require 'nodes/sslconvert'
require 'nodes/req'
require 'nodes/exception'

