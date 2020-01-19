# encoding: utf-8
#
# Redmine plugin for provides a resubmission tool for issues
#
# Copyright © 2018-2020 Stephan Wenzel <stephan.wenzel@drwpatent.de>
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
#

class ResubmissionsController < ApplicationController
  
  unloadable
  
  before_action :authorize_global
  
  # ------------------------------------------------------------------------------------ #
  def test_resubmission_rule 
  
    @startdate           = Date.parse(params[:startdate]) rescue Date.today 
    @new_date, @new_rule = RedmineAutoResubmission.calcfuturedate( @startdate, params[:rule] )
    @feedback_tag        = params[:feedback_tag]
    
    respond_to do |format|
      format.js   { } # renders calc_date.js.erb
    end
    
  rescue Exception => e 
    flash[:error] = e.message
    redirect_back_or_default plugin_settings_path("redmine_auto_resubmission")
  end #def
  
  # ------------------------------------------------------------------------------------ #
  def calc_resubmissions
    
    num = RedmineAutoResubmission.calc_all_resubmission_dates
    flash[:notice] = l(:text_successful_resubmission, :num => num )
    redirect_back_or_default plugin_settings_path("redmine_auto_resubmission")
    
  rescue Exception => e
  
    Rails.logger.info e.message
    Rails.logger.info e.backtrace.join("\n")
    
    flash[:error] = e.message
    redirect_back_or_default plugin_settings_path("redmine_auto_resubmission")
  end #def
  
end #class