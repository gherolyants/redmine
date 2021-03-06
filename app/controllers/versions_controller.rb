# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class VersionsController < ApplicationController
  menu_item :roadmap
  model_object Version
  before_filter :find_model_object, :except => [:new, :close_completed]
  before_filter :find_project_from_association, :except => [:new, :close_completed]
  before_filter :find_project, :only => [:new, :close_completed]
  before_filter :authorize

  helper :custom_fields
  helper :projects
  
  def show
    @issues = @version.fixed_issues.visible.find(:all,
      :include => [:status, :tracker, :priority],
      :order => "#{Tracker.table_name}.position, #{Issue.table_name}.id")
  end
  
  def new
    @version = @project.versions.build
    if params[:version]
      attributes = params[:version].dup
      attributes.delete('sharing') unless attributes.nil? || @version.allowed_sharings.include?(attributes['sharing'])
      @version.attributes = attributes
    end
    if request.post?
      if @version.save
        respond_to do |format|
          format.html do
            flash[:notice] = l(:notice_successful_create)
            redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
          end
          format.js do
            # IE doesn't support the replace_html rjs method for select box options
            render(:update) {|page| page.replace "issue_fixed_version_id",
              content_tag('select', '<option></option>' + version_options_for_select(@project.shared_versions.open, @version), :id => 'issue_fixed_version_id', :name => 'issue[fixed_version_id]')
            }
          end
        end
      else
        respond_to do |format|
          format.html
          format.js do
            render(:update) {|page| page.alert(@version.errors.full_messages.join('\n')) }
          end
        end
      end
    end
  end
  
  def edit
    if request.post? && params[:version]
      attributes = params[:version].dup
      attributes.delete('sharing') unless @version.allowed_sharings.include?(attributes['sharing'])
      if @version.update_attributes(attributes)
        flash[:notice] = l(:notice_successful_update)
        redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
      end
    end
  end
  
  def close_completed
    if request.post?
      @project.close_completed_versions
    end
    redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
  end

  def destroy
    if @version.fixed_issues.empty?
      @version.destroy
      redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
    else
      flash[:error] = l(:notice_unable_delete_version)
      redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
    end
  end
  
  def status_by
    respond_to do |format|
      format.html { render :action => 'show' }
      format.js { render(:update) {|page| page.replace_html 'status_by', render_issue_status_by(@version, params[:status_by])} }
    end
  end

private
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
