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
#
# 1.0.3
#       heavily simplified code
#
# 1.0.4
#       added support for date macro with no arguments => today's date
#
# 1.0.5
#       added support for Rails 5, redmine 4+
#       fixed a bug, in which resubmission could stop
#
# 1.0.6 
#       added support to choose between resubmitting only open tickets or all tickets
#       fixed a bug, in which tickets would not be updated
#       simplified code
#
# 1.0.7
#       addded support for permissions
#       user may be set with rake task to only resubmit issues, which may be edited by 
#       given user
#       
require 'redmine'

Redmine::Plugin.register :redmine_auto_resubmission do
  name 'Redmine Auto Resubmission plugin'
  author 'Stephan Wenzel'
  description 'This plugin provides a resubmission tool for issues'
  version '1.0.7'
  url 'https://github.com/HugoHasenbein/redmine_auto_resubmission'
  author_url 'https://github.com/HugoHasenbein/redmine_auto_resubmission'
  
  settings :default => {'custom_field_id_date'            => '',
                        'custom_field_id_rule'            => '',
                        'custom_field_id_start_date_rule' => '',
                        'custom_field_id_due_date_rule'   => '',
                        'issue_resubmit_status_id'        => '',
                        'resubmission_notice'   => "automatically resubmitted by plugin 'Redmine Auto Resubmission'"
                        },
           :partial => 'redmine_auto_resubmission/auto_resubmission_settings'
           
  project_module :redmine_auto_resubmission do
    
    # set permissions
    permission :test_resubmission,
               :resubmissions => [:test_resubmission_rule]
               
    permission :calc_resubmissions,
               :resubmissions => [:calc_resubmissions]
               
  end
end

require 'redmine_auto_resubmission'