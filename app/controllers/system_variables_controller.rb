class SystemVariablesController < ApplicationController
  before_filter :require_admin

  # GET /system_variables
  # GET /system_variables.xml
  def index
    @system_variables = SystemVariable.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @system_variables }
    end
  end

  # GET /system_variables/1
  # GET /system_variables/1.xml
  def show
    @system_variable = SystemVariable.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @system_variable }
    end
  end

  # GET /system_variables/new
  # GET /system_variables/new.xml
  def new
    @system_variable = SystemVariable.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @system_variable }
    end
  end

  # GET /system_variables/1/edit
  def edit
    @system_variable = SystemVariable.find(params[:id])
  end

  # POST /system_variables
  # POST /system_variables.xml
  def create
    @system_variable = SystemVariable.new(params[:system_variable])

    respond_to do |format|
      if @system_variable.save
        flash[:notice] = 'SystemVariable was successfully created.'
        format.html { redirect_to(@system_variable) }
        format.xml  { render :xml => @system_variable, :status => :created, :location => @system_variable }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @system_variable.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /system_variables/1
  # PUT /system_variables/1.xml
  def update
    @system_variable = SystemVariable.find(params[:id])

    respond_to do |format|
      if @system_variable.update_attributes(params[:system_variable])
        flash[:notice] = 'SystemVariable was successfully updated.'
        format.html { redirect_to(@system_variable) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @system_variable.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /system_variables/1
  # DELETE /system_variables/1.xml
  def destroy
    @system_variable = SystemVariable.find(params[:id])
    @system_variable.destroy

    respond_to do |format|
      format.html { redirect_to(system_variables_url) }
      format.xml  { head :ok }
    end
  end
end
