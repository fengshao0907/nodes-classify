require 'digest'

class HomeController < ApplicationController
    skip_before_filter :verify_authenticity_token
    protected
    @@msg_illegal_request = "illegal request!"
    @@msg_illegal_expression = "illegal expression: %s"
    @@msg_mismatch_key = "key mismatch!"
    @@msg_not_authenticated = 'You need be authenticated first!'
    @@msg_group_need = "You need to be %s to do this!"
    @@msg_no_node = "%s: no such node!"
    @@msg_no_tag = "%s: no such tag!"
    @@msg_no_tagsegment = "%s: no such tag segment!"
    @@msg_no_segment = "%s: no such tag segment!"
    @@msg_no_project = "%s: no such project!"
    @@msg_specify_tag_segment = 'Please specified the tag segment!'
    @@msg_specify_project = 'Please specified the project!'
    @@msg_specify_tag = 'Please specified the tag!'
    @@msg_invalid_tag = 'invalid character in tag!tag names only contain "a-z A-Z 0-9 _"'
    @@msg_invalid_dscription_encode = 'invalid encode for the description, please ensure you use utf-8 for description!'
    @@msg_no_permission_for_tag = "no permission for tag: %s"
    @@msg_no_auth_key = 'auth key does not exist, contact administrator add you public key.'
    @@msg_no_project_tag = 'must have one project tag for node.'

    public
    def index
    end

    def treelist
        @tree = []
        tag_segment_list = TagSegment.all
        tag_segment_list.each do |tag_segment|
            tag_segment[:children] = tag_segment.tags
            @tree << tag_segment
        end
        render json: @tree
    end

    def preauth
        res = {
            :status => 1,
            :msg => @@msg_no_auth_key,
        }

        unless (auth_key = AuthKey.find_by_md5 params[:pubmd5]) == nil
            @pkey = get_pkey(auth_key.keytype, auth_key.keydata)

            res[:status] = 0
            session[:info], res[:server_info] = sign auth_key.keytype
            session[:pubmd5] = params[:pubmd5]
            res.delete(:msg)
        end
        render json: res
    end

    def auth
        res = {
            :status => 1,
            :msg => @@msg_illegal_request
        }
        render json: res && return unless session[:pubmd5] && session[:info]

        auth_key = AuthKey.find_by_md5 session[:pubmd5]
        @pkey = get_pkey(auth_key.keytype, auth_key.keydata)
        if verify(auth_key.keytype, session[:info], params[:client_info])
            res[:status] = 0
            session[:usergroup] = auth_key.usergroup
            res.delete(:msg)
        else
            res[:msg] = @@msg_mismatch_key
        end
        session.delete(:info)
        session.delete(:pubmd5)
        render json: res
    end

    def authenticated?(groupas = nil)
        if !defined?(session[:usergroup]) || session[:usergroup] == nil
            render json: {:status => 1, :msg => @@msg_not_authenticated}
            return false
        end
        if groupas != nil && session[:usergroup] != groupas
            render json: {:status => 1, :msg => @@msg_group_need % groupas}
            return false
        end
        return true
    end

    protected
    def valid_tag?(tag)
        return tag =~ /^\w+$/
    end

    def empty?(obj)
        return true unless defined?(obj) && obj != nil
        return true if obj.length == 0
        return false
    end

    def dump_db(msg = 'dump and backup sql')
        if system('%s/script/db dump' % Rails.root)
            #cmd = 'git commit -o -m "%s" -- %s/db/data.sql' % [msg, Rails.root]
            #unless system(cmd)
            #    logger.warn('git commit failed! CMD: %s' % cmd)
            #    return false
            #end
            #logger.info('db dumped and commit')
            return true
        else
            logger.warn('db dump failed!')
            return false
        end
    end

    def read_tags_cache(node)
        after_read_cache(Rails.cache.read(gen_cache_key('tags', node)))
    end

    def write_tags_cache(node_base64, node_data)
        key = gen_cache_key('tags', node_base64)
        Rails.cache.write(key, before_write_cache(node_data))
    end

    def read_nodes_cache(project, expression, status)
        after_read_cache(Rails.cache.read(gen_cache_key('nodes', status, expression, project)))
    end

    def write_nodes_cache(project, expression, status, servers)
        key = gen_cache_key('nodes', status, expression, project)
        Rails.cache.write(key, before_write_cache(servers))
    end

    def after_read_cache(v)
        return JSON.load(v) unless v.nil?
        nil
    end

    def before_write_cache(v)
        v.to_json
    end

    def gen_cache_key(*keys)
        Digest::MD5.hexdigest(keys.join('_'))
    end

    def clear_cache
        Rails.cache.clear
    end

    private
    def get_pkey(keytype, keydata)
        keytype == 'rsa' ? OpenSSL::PKey::RSA.new(keydata) : OpenSSL::PKey::DSA.new(keydata)
    end

    def sign(keytype, len=16)
        info = random_info len
        server_info = case keytype
            when 'rsa'; @pkey.public_encrypt(info)
            when 'dsa'; info
        end
        [info, server_info].map{ |v| Base64.encode64 v }
    end

    def verify(keytype, info, client_info)
        info = Base64.decode64 info
        client_info = Base64.decode64 client_info
        return case keytype
            when 'rsa'; client_info == info
            when 'dsa'; @pkey.sysverify(info, client_info)
        end
    end

    def random_info(len=16)
        chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
        info = ''
        len.times { |i| info << chars[rand(chars.size-1)] }
        return OpenSSL::Digest::SHA1.digest(info)
    end
end
