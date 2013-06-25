class TagSegmentsController < HomeController
    def create
        deal_proc = Proc.new do |segment, description, failed_segments, successed|
            segment_obj = TagSegment.new(:name => segment)
            segment_obj.description = description if description != nil

            failed_segments.push('%s:%s' % [segment, segment_obj.errors.full_messages.join(';')]) and next unless segment_obj.save
            successed.push segment
        end
        write('create', deal_proc)
    end

    def delete
        deal_proc = Proc.new do |segment, description, failed_segments, successed|
            segment_obj = TagSegment.where(:name => segment)
            failed_tags.push(@@msg_no_segment % segment) and next if empty?(segment_obj)
            segment_obj = segment_obj[0]

            clear_cache
            segment_obj.destroy
            successed.push segment
        end
        write('delete', deal_proc)
    end

    private
    def write(type, deal_proc)
        render json: {:status => 1, :msg => @@msg_specify_tag_segment} and return if empty?(params[:segments])
        return unless authenticated?('root')
        segments = params[:segments].upcase.gsub(/\s/, '').split(',').uniq

        if type == 'create'
            description = empty?(params[:description]) ? nil : params[:description]
            render json: {:status => 1, :msg => @@msg_invalid_dscription_encode} and return unless description.nil? || description.valid_encoding?
        else
            description = nil;
        end

        failed_segments = []
        successed = []
        segments.each { |segment| deal_proc.call(segment, description, failed_segments, successed) }
        res = {:status => 0}
        res[:failed] = failed_segments.join("\n\t") unless empty?(failed_segments)
        res[:successed] = successed.join("\n\t") unless empty?(successed)
        res[:success] = successed.length

        render json: res
    end
end
