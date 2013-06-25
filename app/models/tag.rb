class Tag < ActiveRecord::Base
    validates :name, :presence => true, :length => { :in => 1..20 }
	validates_uniqueness_of :name, :scope =>"project_id"
	belongs_to :project
	has_and_belongs_to_many :servers
	belongs_to :tag_segment

    def self.find_by_server(server)
        server = server.split(',') unless server.index(',') == nil
        server_list = Server.where(:name => server)
        return nil if server_list.length == 0
        res = []; server_list.each { |server| res |= server.tags }
        res.each { |tag| tag[:tag_segment_name] = tag.tag_segment.name }
        res
    end
end
