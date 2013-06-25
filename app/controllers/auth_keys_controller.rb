class AuthKeysController < HomeController
    def create
        return unless authenticated?('root')
        auth_key = AuthKey.new
        auth_key.usergroup = params[:usergroup]
        auth_key.keytype = params[:keytype]
        auth_key.keydata = params[:keydata]
        auth_key.md5 = Digest::MD5.hexdigest auth_key.keydata
        render json: {:status => 1, :msg => auth_key.errors.to_s} and return unless auth_key.save

        #dump_db('add new auth_key for %s to db' % params[:usergroup])
        render json: {:status => 0}
    end
end
