#encoding: utf-8
#
# Nodes异常类
#
# Author:: Guy
# Date:: 2012-08-30
#
class Nodes::Exception < StandardError
    #
    # - :erron
    #     错误号
    #
    attr_reader :erron

    #
    # 初始化异常类
    #
    # - no
    #     错误号
    #
    # - msg
    #     错误信息
    #
    def initialize(no, msg)
        @erron = no
        super msg
    end

    def to_s
        '%s:%s' % [@erron, super]
    end
end
