class ServersController < HomeController
    def create
        deal_proc = Proc.new do |node, status, tags, project, failed_nodes, successed|
            node_obj = Server.new(:name => node, :project_id => project.id, :status => status)

            failed_nodes.push("%s:%s" % [node, node_obj.errors.full_messages.join(';')]) and next unless node_obj.save
            tags.each { |tag| node_obj.tags << tag }
            successed.push node
        end
        write('offline', deal_proc, 'create')
    end

    def update
        deal_proc = Proc.new do |node, status, tags, project, failed_nodes, successed|
            node_obj = Server.where(:name => node)
            failed_nodes.push(@@msg_no_node % node) and next if empty?(node_obj)

            node_obj = node_obj[0]

            unless empty?(tags)
                del_tags = node_obj.tags - tags
                del_tags.each { |tag| node_obj.tags.delete(tag) }
                (tags - node_obj.tags).each { |tag| node_obj.tags << tag }
            end

            unless status==nil
                node_obj.status = status
                failed_nodes.push("%s:%s" % [node, node_obj.errors[:status]]) and next unless node_obj.save
            end
            successed.push node
        end
        write(nil, deal_proc, 'update')
    end

    def delete
        deal_proc = Proc.new do |node, status, tags, project, failed_nodes, successed|
            node_obj = Server.where(:name => node)
            failed_nodes.push(@@msg_no_node % node) and next if empty?(node_obj)
            node_obj = node_obj[0]
            node_obj.tags.delete_all
            node_obj.destroy
            successed.push node
        end
        write(nil, deal_proc, 'delete')
    end

    private
    def get_tags(project)
        tags = params[:tags].gsub(/\s/, '').split(',').uniq
        tags.map do |tag|
            rtag = Tag.where(:name => tag, :project_id => project.id)
            render json: {:status => 1, :msg => @@msg_no_tag % tag} and return nil if empty?(rtag)
            rtag[0]
        end
    end


    def write(default_status, deal_proc, type)
        render json: {:status => 1, :msg => @@msg_specify_project} and return if empty?(params[:projects])
        return unless authenticated?(params[:projects])
        nodes = params[:nodes].gsub(/\s/, '').split(',').uniq
        project = Project.find_by_name(params[:projects])
        render json: {:status => 1, :msg => @@msg_no_project} and return if project == nil
        case type
        when 'create'
            return if (tags = get_tags(project)) == nil
            render json: {:status => 1, :msg => @@msg_specify_tag} and return if empty?(tags)
            status = params[:status] || default_status
        when 'update'
            tags = []
            return if !params[:tags].empty? && (tags = get_tags(project)) == nil
            status = params[:status] || default_status
        when 'delete'
            tags = nil; status = nil;
        end

        failed_nodes = []
        successed = []
        nodes.each { |node| deal_proc.call(node, status, tags, project, failed_nodes, successed) }
        clear_cache
        res = {:status => 0}
        res[:failed] = failed_nodes.join("\n\t") unless empty?(failed_nodes)
        res[:successed] = successed.join("\n\t") unless empty?(successed)
        res[:success] = successed.length

        #dump_db('servers updated') if res[:success] > 0
        render json: res
    end
end
