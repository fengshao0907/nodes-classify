class ProjectsController < HomeController
    def create
        deal_proc = Proc.new do |project, description, failed_projects, successed|
            project_obj = Project.new(:name => project)
            project_obj.description = description if description != nil

            failed_projects.push('%s:%s' % [project, project_obj.errors.full_messages.join(';')]) and next unless project_obj.save
            successed.push project
        end
        write('create', deal_proc)
    end

    def delete
        deal_proc = Proc.new do |project, description, failed_projects, successed|
            project_obj = Project.where(:name => project)
            failed_tags.push(@@msg_no_project % project) and next if empty?(project_obj)
            project_obj = project_obj[0]

            clear_cache
            project_obj.destroy
            successed.push project
        end
        write('delete', deal_proc)
    end

    private
    def write(type, deal_proc)
        render json: {:status => 1, :msg => @@msg_specify_project} and return if empty?(params[:projects])
        return unless authenticated?('root')
        projects = params[:projects].gsub(/\s/, '').split(',').uniq

        if type == 'create'
            description = empty?(params[:description]) ? nil : params[:description]
            render json: {:status => 1, :msg => @@msg_invalid_dscription_encode} and return unless description.nil? || description.valid_encoding?
        else
            description = nil;
        end

        failed_projects = []
        successed = []
        projects.each { |project| deal_proc.call(project, description, failed_projects, successed) }
        res = {:status => 0}
        res[:failed] = failed_projects.join("\n\t") unless empty?(failed_projects)
        res[:successed] = successed.join("\n\t") unless empty?(successed)
        res[:success] = successed.length

        render json: res
    end
end
