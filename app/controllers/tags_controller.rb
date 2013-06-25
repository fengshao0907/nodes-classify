class TagsController < HomeController
    def create
        deal_proc = Proc.new do |tag, segment, project, description, failed_tags, successed|
            failed_tags.push('%s:%s' % [tag, @@msg_invalid_tag]) and next unless valid_tag?(tag)

            tag_obj = Tag.new(:name => tag, :tag_segment_id => segment.id, :project_id => project.id)
            tag_obj.description = description if description != nil

            failed_tags.push('%s:%s' % [tag, tag_obj.errors.full_messages.join(';')]) and next unless tag_obj.save
            successed.push tag
        end
        write('create', deal_proc)
    end

    def delete
        deal_proc = Proc.new do |tag, segment, project, description, failed_tags, successed|
            failed_tags.push('%s:%s' % [tag, @@msg_invalid_tag]) and next unless valid_tag?(tag)
            tag_obj = Tag.where(:name => tag, :project_id => project.id)
            failed_tags.push(@@msg_no_tag % tag) and next if empty?(tag_obj)
            tag_obj = tag_obj[0]

            clear_cache
            tag_obj.servers.delete_all
            tag_obj.destroy
            successed.push tag
        end
        write('delete', deal_proc)
    end

    private
    def write(type, deal_proc)
        render json: {:status => 1, :msg => @@msg_specify_project} and return if empty?(params[:projects])
        return unless authenticated?(params[:projects])
        tags = params[:tags].gsub(/\s/, '').split(',').uniq
        project = Project.find_by_name(params[:projects])
        render json: {:status => 1, :msg => @@msg_no_project % params[:projects]} and return if project == nil

        if type == 'create'
            render json: {:status => 1, :msg => @@msg_specify_tag_segment} and return if empty?(params[:segments])
            segment = TagSegment.find_by_name(params[:segments])
            render json: {:status => 1, :msg => @@msg_no_segment % params[:segments]} and return if segment == nil
            description = empty?(params[:description]) ? nil : params[:description]
            render json: {:status => 1, :msg => @@msg_invalid_dscription_encode} and return unless description.nil? || description.valid_encoding?
        else
            segment = nil; description = nil;
        end

        failed_tags = []
        successed = []
        tags.each { |tag| deal_proc.call(tag, segment, project, description, failed_tags, successed) }
        res = {:status => 0}
        res[:failed] = failed_tags.join("\n\t") unless empty?(failed_tags)
        res[:successed] = successed.join("\n\t") unless empty?(successed)
        res[:success] = successed.length

        #dump_db('tags updated') if res[:success] > 0
        render json: res
    end
end
