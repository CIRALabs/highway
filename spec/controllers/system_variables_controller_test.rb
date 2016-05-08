
if false
class SystemVariablesControllerTest < ActionController::TestCase
  fixtures :system_variables

  def setup
    ptadmin_login
  end

  def test_should_get_index
    ptadmin_login
    get :index
    assert_response :success
    assert_not_nil assigns(:system_variables)
  end

  def test_should_get_new
    ptadmin_login
    get :new
    assert_response :success
  end

  def test_should_create_system_variable
    assert_difference('SystemVariable.count') do
      ptadmin_login
      post :create, :system_variable => { :variable => 'var2', :value => 'hello' }
    end

    assert_redirected_to system_variable_path(assigns(:system_variable))
  end

  def test_should_show_system_variable
    ptadmin_login
    get :show, :id => system_variables(:one).id
    assert_response :success
  end

  def test_should_get_edit
    ptadmin_login
    get :edit, :id => system_variables(:one).id
    assert_response :success
  end

  def test_should_update_system_variable
    ptadmin_login
    put :update, :id => system_variables(:one).id, :system_variable => { }
    assert_redirected_to system_variable_path(assigns(:system_variable))
  end

  def test_should_destroy_system_variable
    assert_difference('SystemVariable.count', -1) do
      ptadmin_login
      delete :destroy, :id => system_variables(:one).id
    end

    assert_redirected_to system_variables_path
  end
end
end
