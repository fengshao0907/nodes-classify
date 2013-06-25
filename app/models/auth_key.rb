class AuthKey < ActiveRecord::Base
    validates :md5, :presence => true, :uniqueness => true
	validates_presence_of :usergroup, :keydata
	validates_inclusion_of :keytype, :in => ['rsa', 'dsa']

    def self.find_by_md5(md5)
        res = where(:md5 => md5)
        return res.count > 0 ? res[0] : nil
    end
end
