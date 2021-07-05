module RedmineOpenidConnect
  module UsersControllerPatch

    def destroy
      OicSession.where("user_id = ? ", @user.id).delete_all
      super
    end
  end    
end
