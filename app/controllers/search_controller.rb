class SearchController < HomeController
    def nodes
        status = params[:status] || '%'
        project = Project.find_by_name(params[:project])
        render json: {:status => 1, :msg => @@msg_no_project % params[:project]} and return if project == nil
        project_id = project.id
        if params[:logic_expression].nil?
        	cache = read_nodes_cache(params[:project], params[:logic_expression], status)
        	render json: {:status => 0, :data => cache} and return unless cache.nil?
            @servers = Server.where(:project_id => project_id)
        	write_nodes_cache(params[:project], params[:logic_expression], status, @servers)
        else
        	cache = read_nodes_cache(params[:project], params[:logic_expression], status)
	        render json: {:status => 0, :data => cache} and return unless cache.nil?
	        exp = ActiveSupport::Base64.decode64(params[:logic_expression]).gsub(/\s/, '')
	        oper = []
        	open = []
        	illegal = { :status => 1, :msg => @@msg_illegal_expression % exp }
        	exp_length = exp.length
        	operator = /[\[\],\+]/
        	offset = 0
        	begin
        	    if exp[offset] =~ operator
        	        o = exp[offset]
        	        offset += 1

        	        while oper.length > 0 && get_oper_priority(oper.last) >= get_oper_priority(o)
        	            so = oper.pop
        	            if so == '[' && o == ']'
        	                o = nil
        	            else
        	                render json: illegal and return unless calc(open, so)
        	            end
        	        end if o != '['
        	        oper.push(o) if o
        	    else
        	        next_offset = exp.index(operator, offset) || 0
        	        return unless (ids = get_tag_server_ids(exp[offset..(next_offset-1)], project_id, status))
        	        open << ids
        	        offset = next_offset
        	    end
        	end until offset == 0 || offset >= exp_length

        	render json: illegal and return unless calc(open, oper.pop) until oper.length == 0
        	render json: illegal and return unless open.length == 1

        	@servers = Server.where(:id => open[0])
        	write_nodes_cache(params[:project], params[:logic_expression], status, @servers)
		end
        render json: {:status => 0, :data => @servers}
    end

    def tags
        cache = read_tags_cache(params[:node])
        render json: {:status => 0, :data => cache} and return unless cache.nil?

        node = ActiveSupport::Base64.decode64(params[:node]).gsub(/\s/, '')
        @server = Server.where(:name => node).first
        render json: {:status => 1, :msg => @@msg_no_node % node} and return if @server.nil?
        @server_data = {
            :status => @server.status,
            :tags => [],
        }
        @server.tags.each { |t| @server_data[:tags] << [t.tag_segment.name, t.name] }
        write_tags_cache(params[:node], @server_data)
        render json: {:status => 0, :data => @server_data }
    end

    def tag_segment
        tag = ActiveSupport::Base64.decode64(params[:tag])
		project = Project.find_by_name(params[:project])
		render json: {:status => 1, :msg => @@msg_no_project % params[:project]} and return if project == nil
        tag_obj = Tag.where(:name => tag, :project_id => project.id).first
        render json: {:status => 1, :msg => @@msg_no_tag % tag} and return if tag_obj.nil?
        render json: {:status => 0, :data => tag_obj.tag_segment.name}
    end

    def taglist
		project = Project.find_by_name(params[:project])
		render json: {:status => 1, :msg => @@msg_no_project % params[:project]} and return if project == nil
        segment = ActiveSupport::Base64.decode64(params[:segment]).upcase
        segment_obj = TagSegment.where(:name => segment).first
        render json: {:status => 1, :msg => @@msg_no_tagsegment % segment} and return if segment_obj.nil?
		@tags = segment_obj.tags.map { |t_o|
			if t_o.project_id == project.id
				t_o.name
			end
		}
        render json: {:status => 0, :data => @tags}
    end

    private
    def get_tag_server_ids(tag, project_id, status)
        render json: {:status => 1, :msg => @@msg_no_tag % tag } and return nil unless (servers = Server.find_by_tag(tag, project_id, status))
        servers.map { |s| s.id }
    end

    def calc(open, o)
        return false if open.length < 2
        open.push(o=='+' ? open.pop & open.pop : open.pop | open.pop)
    end

    def get_oper_priority(oper)
        case oper
            when ','; 1
            when '+'; 2
            when '['; -1
            when ']'; -1
            else    ; 0
        end
    end

end
