# encoding: utf-8
#
# Redmine plugin for provides a resubmission tool for issues
#
# Copyright © 2018 Stephan Wenzel <stephan.wenzel@drwpatent.de>
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

Redmine::Plugin.register :redmine_auto_resubmission do
  name 'Redmine Auto Resubmission plugin'
  author 'Stephan Wenzel'
  description 'This plugin provides a resubmission tool for issues'
  version '1.0.2'
  url 'https://github.com/HugoHasenbein/redmine_auto_resubmission'
  author_url 'https://github.com/HugoHasenbein/redmine_auto_resubmission'

  settings :default => {'custom_field_id_date' 	=> '0',
                        'custom_field_id_rule' 	=> '0',
                        'issue_status_id' 		=> '0',
                        'resubmission_notice' 	=> 'resubmitted'
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