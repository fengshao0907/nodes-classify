class Server < ActiveRecord::Base
    validates :name, :presence => true, :uniqueness => true
	validates_inclusion_of :status, :in => ['running', 'offline']
	belongs_to :project
	has_and_belongs_to_many :tags

    def self.find_by_tag(tag, project_id, status='%')
        tag = tag.split(',') unless tag.index(',') == nil
        tag_list = Tag.where(:name => tag, :project_id => project_id)
        return nil if tag_list.length == 0
        res = []; tag_list.each { |tag| res |= tag.servers.where('status LIKE ?', status) }
        res
    end
end
