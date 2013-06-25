#encoding: utf-8
require 'openssl'
require 'base64'

#
# 提供将OpenSSH格式的公钥转换为OpenSSL的PEM格式支持
# 
# Author:: Guy
# Date:: 2012-08-30
#
class Nodes::SSLConvert
    #
    # 转换RSA公钥编码为PEM格式
    #
    # * sshkey
    #     .pub结尾的ssh格式rsa公钥
    #
    def self.rsa_pub_ssh2pem(sshkey)
        type, blob64, comment = *sshkey.strip.split
        blob = Base64.decode64(blob64)
        raise Nodes::Exception.new(Nodes::PUBLICKEY_TYPE_ERROR, "unsupported key type: #{type}") unless type == 'ssh-rsa'
        values = []
        3.times do
            length = blob.slice!(0, 4).unpack('I!>').first
            data = blob.slice!(0, length)
            values << data
        end
        blob_key_type, *ns = *values
        bns = ns.map { |i| OpenSSL::BN.new(i, 2) }
        key2 = OpenSSL::PKey::RSA.new
        key2.e, key2.n = *bns
        key2
    end

    #
    # 转换DSA公钥编码为PEM格式
    #
    # - sshkey
    #     .pub结尾的ssh格式dsa公钥
    #
    def self.dsa_pub_ssh2pem(sshkey)
        type, blob64, comment = *sshkey.strip.split
        blob = Base64.decode64(blob64)
        raise Nodes::Exception.new(Nodes::PUBLICKEY_TYPE_ERROR, "unsupported key type: #{type}") unless type == 'ssh-dss'
        values = []
        5.times do
            length = blob.slice!(0, 4).unpack('N').first
            data = blob.slice!(0, length)
            values << data
        end
        blob_key_type, *ns = *values
        bns = ns.map { |i| OpenSSL::BN.new(i, 2) }
        key2 = OpenSSL::PKey::DSA.new
        key2.p, key2.q, key2.g, key2.pub_key = *bns
        key2
    end
end
