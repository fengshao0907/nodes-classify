class TagSegment < ActiveRecord::Base
    validates :name, :presence => true, :uniqueness => true, :length => { :in => 1..16 }
	has_many :tags, :dependent => :delete_all

    def self.find_by_name(name)
        segment = where(:name => name)
        return nil if segment.length == 0
        segment[0]
    end
end
