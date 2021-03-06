require 'json'
class UsersController < ApplicationController
  before_action :set_user, only: [:info, :add_repo, :cp_file, :cp_gaz]
  #before_action :set_repo_path, only: [:cp_file, :cp_gaz, :add_repo]

  layout "main_layout",:only => [:login]


  def info
    @user_repo_array = []
    @user_repo_info = []

    ReposUser.where("user_id='"+@user.id.to_s+"'").find_each do |repo|

      Repo.where("id='"+repo.repo_id.to_s+"'").find_each do |re|
        url = @user.username + "/" + re.repo_name
        @user_repo_array << url
        @user_repo_info << [re.repo_name, re.entities, re.language]
      end

    end

  end


  def repo_status_initializer
    return "ssss"
    $line_num = 1
    $prev_line_num = 1
    $seed_status = true
    $seed_line_annotated = 0
    $seed_line_total = 0
    $corpus_line_annotated = 0
    $corpus_line_total = 0
    $time = 1

  end

  def cp_gaz

    data = request.body.read

    name = @user.repos[-1].id.to_s + "_" + @user.repos[-1].repo_name

    dir = 'HER-data/' + name + "/Data/Gazatteers/"
    file_count = Dir[File.join(dir, '**', '*')].count { |file| File.file?(file) }

    Dir.chdir 'HER-data/'

    File.open("temp"+file_count.to_s+".txt", 'wb') { |file| file.write(data) }
    system("sed", "-i", "1,4d;$d", "temp"+file_count.to_s+".txt")
    system("mv", "temp"+file_count.to_s+".txt", name+"/Data/Gazatteers/")

    Dir.chdir '../'

    respond_to do |format|

      msg = {:status => true}

      format.json {render :json => msg}

    end
  end


  def cp_file

    data = request.body.read

    name = @user.repos[-1].id.to_s + "_" + @user.repos[-1].repo_name

    dir = 'HER-data/' + name + "/Data/Original/"
    file_count = Dir[File.join(dir, '**', '*')].count { |file| File.file?(file) }

    Dir.chdir 'HER-data/'

    File.open("temp"+file_count.to_s+".txt", 'wb') { |file| file.write(data) }
    system("sed", "-i", "1,4d;$d", "temp"+file_count.to_s+".txt")
    system("mv", "temp"+file_count.to_s+".txt", name+"/Data/Original/")

    Dir.chdir '../'
    puts "**************************"

    respond_to do |format|

      msg = {:status => true}

      format.json {render :json => msg}

    end

  end

  def repo_directory_setup repo

    Dir.chdir "HER-data"
    name = repo.id.to_s + "_" + repo.repo_name.to_s
    system("mkdir", name)
    Dir.chdir "../HER-core"
    system('sh', 'Scripts/set_up.sh', "../HER-data/"+name)



    # i = 0
    # File.open("temp"+i.to_s+".txt", 'wb') { |file| file.write(files) }
    # system("sed", "-i", "1,4d;$d", "temp"+i.to_s+".txt")
    # system("mv", "temp"+i.to_s+".txt", name+"/Data/Original/")
    # i += 1
    #
    #
    # # gazs.each do |data|
    # #   File.open("temp.txt", 'wb') { |file| file.write(data) }
    # #   system("sed", "-i", "1,4d;$d", "temp.txt")
    # #   system("mv", "temp.txt", name+"/Data/Gazatteers/")
    # # end

    Dir.chdir "../"

  end





  def add_repo

    repo_info = request.body.read

    repo_info = JSON.parse(repo_info)


    repo_name = repo_info["repo_name"]
    language = repo_info["language"]
    seed_size = repo_info["seed_size"]
    sort_method = repo_info["sort_method"]
    entities = repo_info["entities"]
    user_id = @user.id


    Repo.new(:repo_name => repo_name,
             :language => language,
             :seed_size => seed_size.to_i,
             :sort_method => sort_method,
             :entities => entities,
             :status => repo_status_initializer).save

    User.find_by_id(user_id).repos << Repo.last

    repo_directory_setup Repo.last

    respond_to do |format|

      msg = {:status => true}

      format.json {render :json => msg}

    end



  end

  def create

    account_info = request.body.read
    account_info = JSON.parse(account_info)
    username = account_info["username"]
    password = account_info["password"]

    status = true

    if User.where(:username => username).blank?
        User.new(:username => username, :password=>password).save
     else
        status = false
    end
    respond_to do |format|

      msg = {:status => status}

      format.json {render :json => msg}

    end

  end

  def validate

    account_info = request.body.read
    account_info = JSON.parse(account_info)
    username = account_info["username"]
    password = account_info["password"]

    if User.where(["username = ? and password = ?", username, password]).blank?

      respond_to do |format|

        msg = {:status => false}

        format.json {render :json => msg}

      end

    else

      respond_to do |format|

        msg = {:status => true}

        format.json {render :json => msg}

      end


    end


  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find_by_username(params[:username])
    end

    def set_repo_path

    end

    def user_params
      params.require(:user).permit(:username, :password)
    end

end

