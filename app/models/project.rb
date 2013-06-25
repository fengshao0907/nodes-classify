class Project < ActiveRecord::Base
    validates :name, :presence => true, :uniqueness => true, :length => { :in => 1..20 }
    has_many :servers, :dependent => :delete_all
    has_many :tags, :dependent => :delete_all

    def writeable?(usergroup)
        return true if usergroup == 'root'
    end

    def self.find_by_name(name)
        project = where(:name => name)
        return nil if project.length == 0
        project[0]
    end
end
