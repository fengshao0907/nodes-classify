#encoding: utf-8
require 'net/http'
require 'json'

#
# HTTP请求工具封装
# Author:: Guy
# Date:: 2012-08-30
#
class Nodes::Req
    #
    # new instance method
    #
    # - service_url
    #     要请求的host
    #
    def initialize(service_url)
        uri = URI.parse service_url
        @http = Net::HTTP.new(uri.host, uri.port)
        @http.open_timeout = 10
        @http.read_timeout = 10
        @url_prefix = uri.path

        @@valid_status = %w{200 201}
    end

    #
    # 发起post请求
    #
    # - uri
    #     url请求路径
    #
    # - data
    #     post的内容hash表
    #
    # - render
    #     是否使用json解析返回内容,true/false.默认解析
    #
    # - headers
    #     http请求头，hash表形式.可省略
    #
    def post(uri, data, render=true, headers={})
        req('post', uri, data, render, headers)
    end

    #
    # 发起get请求
    #
    # - uri
    #    url请求路径
    #
    # - render
    #     是否使用json解析返回内容,true/false.默认解析
    #
    # - headers
    #     http请求头，hash表形式.可省略
    #
    def get(uri, render=true, headers={})
        req('get', uri, nil, render, headers)
    end

    private
    def save_cookie(resp)
        cookie_array = []
        resp_cookie = resp.get_fields('set-cookie')
        resp_cookie.each do |cookie|
            cookie_array.push cookie.split('; ')[0]
        end if resp_cookie
        @cookie = cookie_array.join('; ') if cookie_array.length > 0
    end

    def req(type, uri, data=nil, render=true, headers={}, retry_times=3)
        headers.merge!({'Cookie'=>@cookie}) if defined? @cookie

        path = @url_prefix + uri + '.json'

        retry_times.downto(0) do
            @resp = case type
                when 'get'
                    headers.length > 0 ? @http.get(path, headers) : @http.get(path)
                when 'post'
                    data = URI.encode_www_form(data) unless data.nil?
                    headers.length > 0 ? @http.post(path, data, headers) : @http.post(path, data)
                else
                    raise Nodes::Exception.new(Nodes::HTTP_REQUEST_ERROR, 'Method "http_req" type error:'+type)
            end
            break if @@valid_status.include?(@resp.code)
        end

        unless @@valid_status.include?(@resp.code)
            puts "[Net Error]type=#{type};uri=#{uri};data=#{data};render=#{render};headers=#{headers};retry_times=#{retry_times}"
            exit Nodes::HTTP_REQUEST_ERROR
        end

        @resp.value
        save_cookie @resp
        return render ? JSON.parse(@resp.body) : @resp
    end
end
